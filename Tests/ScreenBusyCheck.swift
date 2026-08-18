//
//  ScreenBusyCheck.swift
//  Spellbreak
//
//  Compiles against the real Utilities.swift, so the heuristic under test is the
//  one that ships. Run with: ./scripts/screen-busy-check.sh
//
//  What it pins: a break must not land on top of a fullscreen app, and must land
//  normally the rest of the time. Both halves matter — a detector stuck on "busy"
//  silently stops every break forever, which is worse than the bug it prevents.
//

import AppKit

@main
struct ScreenBusyCheck {
    static func main() {
        guard let screen = NSScreen.main else {
            fputs("no screen available\n", stderr)
            exit(1)
        }

        // 1. Nothing covering a whole screen → breaks are allowed through.
        if ScreenBusy.aFullscreenAppIsRunning() {
            fputs("FAIL: reported fullscreen with no fullscreen window on screen — every break would be held forever\n", stderr)
            exit(1)
        }
        print("ok: idle desktop does not read as busy")

        // 2. A window that exactly covers a screen at the normal layer → held.
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .normal
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))

        let sawIt = ScreenBusy.aFullscreenAppIsRunning()
        window.orderOut(nil)
        window.close()
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))

        if !sawIt {
            fputs("FAIL: a screen-sized window at the normal layer did not read as fullscreen\n", stderr)
            exit(1)
        }
        print("ok: a screen-covering window reads as busy")

        // 3. It goes away again, so breaks resume once the game quits.
        if ScreenBusy.aFullscreenAppIsRunning() {
            fputs("FAIL: still reporting fullscreen after the window closed — breaks would never resume\n", stderr)
            exit(1)
        }
        print("ok: closing it clears the hold")

        print("ScreenBusy check passed")
    }
}
