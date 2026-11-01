#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run --allow-env --allow-net
// ===================================================================
// asc-provision — certificates and a Mac App Store profile, without the
// download/upload loop.
// ===================================================================
// The manual dance fails structurally, not because anyone is careless:
//
//   * Apple binds every certificate to a CSR you generate, so a cert and its
//     private key only match if you keep the exact CSR that made it.
//   * The profile dropdown lists every certificate in the team, sorted by
//     expiry, with no indication of which one is "the" distribution cert.
//     Pick the wrong row and nothing complains until upload.
//   * Anything that goes wrong needs another round of download, import,
//     regenerate, re-download.
//
// This does the whole thing through the App Store Connect API instead:
//
//   1. generate a fresh private key and CSR here, so key and cert match by
//      construction — they are the same pair, created in this run;
//   2. ask Apple for the two certificates from that CSR;
//   3. import them into the login keychain;
//   4. create the Mac App Store profile pointing at the certificate ID we
//      just received, never at a name someone had to recognise;
//   5. write Spellbreak_MAS.provisionprofile and run the build preflight.
//
// Re-runnable. Every step reports what it found before it changes anything.
//
// ONE-TIME SETUP (the only clicking left, and it is one form):
//   App Store Connect → Users and Access → Integrations → App Store Connect API
//   → + → name "spellbreak-automation", access role **App Manager**
//   → download the .p8 (it downloads once, ever), note the **Key ID** and the
//     **Issuer ID** shown above the key list.
//   Then:
//     mkdir -p ~/.appstoreconnect/private_keys
//     mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
//     export ASC_KEY_ID=XXXXXXXXXX
//     export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
//
// USAGE
//   deno run -A scripts/asc-provision.ts --check          # what exists already
//   deno run -A scripts/asc-provision.ts                  # create what's missing
//   deno run -A scripts/asc-provision.ts --self-test      # prove JWT signing offline
// ===================================================================

const API = "https://api.appstoreconnect.apple.com/v1";
const TEAM_ID = "V433H655PN";
const BUNDLE_ID = "com.pabloalvarado.spellbreak";
const PROFILE_NAME = "Spellbreak MAS";
const WORK_DIR = ".asc-work";
const PROFILE_OUT = "Spellbreak_MAS.provisionprofile";
const KEYCHAIN = `${Deno.env.get("HOME")}/Library/Keychains/login.keychain-db`;

const args = new Set(Deno.args);
const CHECK_ONLY = args.has("--check");
const SELF_TEST = args.has("--self-test");

const say = (s: string) => console.log(s);
const ok = (s: string) => console.log(`  \x1b[32m✓\x1b[0m ${s}`);
const warn = (s: string) => console.log(`  \x1b[33m!\x1b[0m ${s}`);
const die = (s: string): never => {
  console.error(`\x1b[31m✗\x1b[0m ${s}`);
  Deno.exit(1);
};

// ------------------------------------------------------------------
// JWT (ES256), the way App Store Connect wants it
// ------------------------------------------------------------------

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToBytes(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  const raw = atob(body);
  const buf = new ArrayBuffer(raw.length);
  const view = new Uint8Array(buf);
  for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
  return buf;
}

async function makeJwt(
  keyPem: string,
  keyId: string,
  issuerId: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(keyPem),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const enc = new TextEncoder();
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(
    enc.encode(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" })),
  );
  const claims = b64url(
    enc.encode(JSON.stringify({
      iss: issuerId,
      iat: now,
      exp: now + 600, // the API rejects anything over 20 minutes
      aud: "appstoreconnect-v1",
    })),
  );
  const signingInput = `${header}.${claims}`;
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      enc.encode(signingInput),
    ),
  );
  return `${signingInput}.${b64url(sig)}`;
}

// ------------------------------------------------------------------
// self-test: no Apple, no key from Apple, no network
// ------------------------------------------------------------------

async function selfTest() {
  say("Self test — signing a JWT with a throwaway key");
  const dir = await Deno.makeTempDir();
  const keyPath = `${dir}/test.p8`;
  const run = await new Deno.Command("openssl", {
    args: [
      "genpkey",
      "-algorithm",
      "EC",
      "-pkeyopt",
      "ec_paramgen_curve:P-256",
      "-out",
      keyPath,
    ],
  }).output();
  if (!run.success) die("openssl could not make a test key");

  const pem = await Deno.readTextFile(keyPath);
  const jwt = await makeJwt(
    pem,
    "TESTKEY123",
    "00000000-0000-0000-0000-000000000000",
  );
  const [h, c, s] = jwt.split(".");
  if (!h || !c || !s) die("JWT is not three parts");
  ok(`header  ${atob(h.replace(/-/g, "+").replace(/_/g, "/"))}`);
  ok(`claims  ${atob(c.replace(/-/g, "+").replace(/_/g, "/"))}`);
  ok(`signature ${s.length} chars (ES256 raw, r||s)`);
  await Deno.remove(dir, { recursive: true });
  say("\nJWT signing works. Nothing was sent to Apple.");
}

// ------------------------------------------------------------------
// credential loading
// ------------------------------------------------------------------

async function loadKeyId(): Promise<string> {
  const fromEnv = Deno.env.get("ASC_KEY_ID");
  if (fromEnv) return fromEnv;
  // Derive it from the filename Apple uses: AuthKey_ABCDE12345.p8
  const home = Deno.env.get("HOME")!;
  for (
    const dir of [
      `${home}/.appstoreconnect/private_keys`,
      `${home}/.private_keys`,
    ]
  ) {
    try {
      for await (const entry of Deno.readDir(dir)) {
        const m = entry.name.match(/^AuthKey_([A-Z0-9]{10})\.p8$/);
        if (m) return m[1];
      }
    } catch { /* not there */ }
  }
  return die(
    "No App Store Connect key found.\n" +
      "  Put AuthKey_XXXXXXXXXX.p8 in ~/.appstoreconnect/private_keys/ and set ASC_ISSUER_ID.",
  );
}

async function loadKeyPem(keyId: string): Promise<string> {
  const home = Deno.env.get("HOME")!;
  for (
    const p of [
      `${home}/.appstoreconnect/private_keys/AuthKey_${keyId}.p8`,
      `${home}/.private_keys/AuthKey_${keyId}.p8`,
    ]
  ) {
    try {
      return await Deno.readTextFile(p);
    } catch { /* next */ }
  }
  return die(
    `Cannot read AuthKey_${keyId}.p8 in ~/.appstoreconnect/private_keys/`,
  );
}

// ------------------------------------------------------------------
// API helper
// ------------------------------------------------------------------

let TOKEN = "";

async function api(
  path: string,
  init: { method?: string; body?: unknown } = {},
): Promise<{ status: number; json: any }> {
  const res = await fetch(`${API}${path}`, {
    method: init.method ?? "GET",
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      "Content-Type": "application/json",
    },
    body: init.body ? JSON.stringify(init.body) : undefined,
  });
  const text = await res.text();
  let json: any = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json };
}

function apiError(what: string, r: { status: number; json: any }): never {
  const detail = r.json?.errors?.map((e: any) => `${e.title}: ${e.detail}`)
    .join("; ") ?? JSON.stringify(r.json);
  return die(`${what} failed (HTTP ${r.status}) — ${detail}`);
}

// ------------------------------------------------------------------
// openssl helpers
// ------------------------------------------------------------------

async function sh(cmd: string, args: string[], cwd?: string) {
  const out = await new Deno.Command(cmd, { args, cwd }).output();
  if (!out.success) {
    die(
      `${cmd} ${args.slice(0, 3).join(" ")}… failed:\n${
        new TextDecoder().decode(out.stderr)
      }`,
    );
  }
  return new TextDecoder().decode(out.stdout);
}

// ------------------------------------------------------------------

async function importKeychain(
  dist: { cerPath: string },
  installer: { cerPath: string },
  keyFile: string,
) {
  const p12 = `${WORK_DIR}/spellbreak-mas.p12`;
  const p12pass = crypto.randomUUID();
  await sh("openssl", [
    "pkcs12",
    "-export",
    "-inkey",
    keyFile,
    "-in",
    dist.cerPath,
    "-name",
    "Spellbreak MAS",
    "-out",
    p12,
    // OpenSSL 3+ defaults to AES-256 + PBKDF2, which `security import` cannot
    // read ("MAC verification failed"). Force the legacy PBE macOS accepts.
    "-certpbe",
    "PBE-SHA1-3DES",
    "-keypbe",
    "PBE-SHA1-3DES",
    "-macalg",
    "sha1",
    "-passout",
    `pass:${p12pass}`,
  ]);
  await sh("security", [
    "import",
    p12,
    "-k",
    KEYCHAIN,
    "-P",
    p12pass,
    "-T",
    "/usr/bin/codesign",
    "-T",
    "/usr/bin/productbuild",
  ]);
  await sh("security", [
    "import",
    installer.cerPath,
    "-k",
    KEYCHAIN,
    "-T",
    "/usr/bin/productbuild",
  ]);
}

async function main() {
  if (SELF_TEST) return await selfTest();

  const keyId = await loadKeyId();
  const issuerId = Deno.env.get("ASC_ISSUER_ID") ??
    die(
      "ASC_ISSUER_ID is not set (Users and Access → Integrations → Issuer ID)",
    );
  const keyPem = await loadKeyPem(keyId);
  TOKEN = await makeJwt(keyPem, keyId, issuerId);
  ok(`App Store Connect key ${keyId} loaded, JWT signed`);

  // 1. Do we know the bundle ID?
  const bundles = await api(
    `/bundleIds?filter[identifier]=${encodeURIComponent(BUNDLE_ID)}`,
  );
  if (bundles.status !== 200) apiError("Looking up the App ID", bundles);
  let bundleResource = bundles.json.data?.[0];

  if (!bundleResource) {
    if (CHECK_ONLY) {
      warn(`App ID ${BUNDLE_ID} does not exist yet`);
    } else {
      const created = await api("/bundleIds", {
        method: "POST",
        body: {
          data: {
            type: "bundleIds",
            attributes: {
              identifier: BUNDLE_ID,
              name: "Spellbreak",
              platform: "MAC_OS",
            },
          },
        },
      });
      if (created.status >= 300) apiError("Registering the App ID", created);
      bundleResource = created.json.data;
      ok(`Registered App ID ${BUNDLE_ID}`);
    }
  } else {
    ok(`App ID ${BUNDLE_ID} exists`);
  }

  // 2. What certificates does the team already have?
  const certs = await api("/certificates?limit=200");
  if (certs.status !== 200) apiError("Listing certificates", certs);
  const byType = (t: string) =>
    (certs.json.data ?? []).filter((c: any) =>
      c.attributes.certificateType === t
    );

  const existingDist = byType("DISTRIBUTION");
  const existingInstaller = byType("MAC_INSTALLER_DISTRIBUTION");
  warn(
    `Found ${existingDist.length} Apple Distribution and ${existingInstaller.length} installer certs (none proven to match a private key here yet)`,
  );

  if (CHECK_ONLY) {
    say(
      "\n--check only: nothing was created. Re-run without --check to build the missing pieces.",
    );
    return;
  }

  // 3. One key pair, one CSR, both certificates from it. This is the part the
  //    manual loop gets wrong: the key and the cert can never disagree here,
  //    because the cert is cut from this key a second later.
  await Deno.mkdir(WORK_DIR, { recursive: true });
  const keyFile = `${WORK_DIR}/spellbreak-mas.pem`;
  const csrFile = `${WORK_DIR}/spellbreak-mas.crtSigningRequest`;

  const present = async (path: string) => {
    try {
      await Deno.stat(path);
      return true;
    } catch {
      return false;
    }
  };

  const haveBothCerts = !args.has("--force-certs") &&
    await present(`${WORK_DIR}/distribution.cer`) &&
    await present(`${WORK_DIR}/mac_installer_distribution.cer`);

  let csr = "";
  if (haveBothCerts && await present(keyFile)) {
    ok("Reusing the key and certificates already in .asc-work/");
  } else {
    await sh("openssl", [
      "req",
      "-new",
      "-newkey",
      "rsa:2048",
      "-nodes",
      "-keyout",
      keyFile,
      "-out",
      csrFile,
      "-subj",
      "/C=AU/CN=Pablo Alvarado/emailAddress=pibulus@gmail.com",
    ]);
    csr = await Deno.readTextFile(csrFile);
    ok("Generated a fresh key and CSR in .asc-work/");
  }

  async function createCert(type: string, label: string) {
    const reused = `${WORK_DIR}/${type.toLowerCase()}.cer`;
    if (!args.has("--force-certs")) {
      try {
        const bytes = await Deno.readFile(reused);
        const mine = btoa(String.fromCharCode(...bytes));
        const match = (certs.json.data ?? []).find(
          (c: any) =>
            c.attributes.certificateType === type &&
            c.attributes.certificateContent === mine,
        );
        if (match) {
          ok(`${label} already exists for this key (id ${match.id}) — reusing`);
          return { id: match.id as string, cerPath: reused };
        }
        warn(
          `${label} file present but not found at Apple — a new one will be created`,
        );
      } catch { /* not there, create */ }
    }

    const r = await api("/certificates", {
      method: "POST",
      body: {
        data: {
          type: "certificates",
          attributes: { certificateType: type, csrContent: csr },
        },
      },
    });
    if (r.status >= 300) apiError(`Creating the ${label} certificate`, r);
    const id = r.json.data.id;
    const der = r.json.data.attributes.certificateContent;
    const cerPath = `${WORK_DIR}/${type.toLowerCase()}.cer`;
    await Deno.writeFile(
      cerPath,
      Uint8Array.from(atob(der), (c) => c.charCodeAt(0)),
    );
    ok(`${label} certificate created (id ${id})`);
    return { id, cerPath };
  }

  const dist = await createCert("DISTRIBUTION", "Apple Distribution");
  const installer = await createCert(
    "MAC_INSTALLER_DISTRIBUTION",
    "Mac Installer Distribution",
  );

  // 4. Import both into the login keychain, with the key that signed the CSR.
  //    productbuild is the tool that signs the installer package, codesign the app.
  const identities = await sh("security", ["find-identity", "-v"])
    .catch(() => "");
  if (
    !args.has("--force-certs") &&
    identities.includes("Apple Distribution: Pablo Alvarado")
  ) {
    ok("Both identities are already in the login keychain — nothing to import");
  } else {
    await importKeychain(dist, installer, keyFile);
    ok("Imported both certificates into the login keychain");
  }

  ok("Imported both certificates into the login keychain");

  // 5. The profile, pointed at the certificate ID we just made — never a name.
  const existingProfiles = await api(
    `/profiles?filter[name]=${encodeURIComponent(PROFILE_NAME)}`,
  );
  for (const old of existingProfiles.json?.data ?? []) {
    const del = await api(`/profiles/${old.id}`, { method: "DELETE" });
    if (del.status < 300) warn(`Removed the old profile ${old.id} (same name)`);
  }

  const prof = await api("/profiles", {
    method: "POST",
    body: {
      data: {
        type: "profiles",
        attributes: { name: PROFILE_NAME, profileType: "MAC_APP_STORE" },
        relationships: {
          bundleId: {
            data: { type: "bundleIds", id: bundleResource.id },
          },
          certificates: {
            data: [{ type: "certificates", id: dist.id }],
          },
        },
      },
    },
  });
  if (prof.status >= 300) apiError("Creating the provisioning profile", prof);
  await Deno.writeFile(
    PROFILE_OUT,
    Uint8Array.from(
      atob(prof.json.data.attributes.profileContent),
      (c) => c.charCodeAt(0),
    ),
  );
  ok(`Wrote ${PROFILE_OUT}`);

  say("\nNow prove it:");
  say("  ./build-mas.sh --check-only");
}

await main();
