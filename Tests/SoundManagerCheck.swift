// Compiles the shipping SoundManager without changing the package manifest:
// swiftc Sources/Spellbreak/Utilities.swift Sources/Spellbreak/SoundManager.swift Sources/Spellbreak/Errors/AppErrors.swift Tests/SoundManagerCheck.swift -o "$TMPDIR/spellbreak-sound-check" && "$TMPDIR/spellbreak-sound-check"

import Foundation

@main
struct SoundManagerCheck {
    static func main() {
        check(0, 0.6, expected: 0)       // Muted means silent, even with ambient enabled.
        check(0.5, 0.6, expected: 0.3)   // Existing ambient gain stays unchanged.
        check(0.5, 0.4, expected: 0.2)   // Control sounds use the same preference.
        check(2, 0.6, expected: 0.6)     // Stale preferences cannot amplify playback.
        check(-1, 0.6, expected: 0)
        check(.nan, 0.6, expected: 0)
        check(.infinity, 0.6, expected: 0)
        check(0.5, .nan, expected: 0)
        print("SoundManager volume check passed")
    }

    private static func check(_ preference: Double, _ scale: Float, expected: Float) {
        let actual = SoundManager.outputVolume(preference: preference, scale: scale)
        precondition(abs(actual - expected) < 0.0001, "unexpected volume: \(actual), expected \(expected)")
    }
}
