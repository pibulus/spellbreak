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
        // 0. Timing clamp & formatting safety checks
        precondition(SpellbreakLimits.clampDuration(.nan) == 20)
        precondition(SpellbreakLimits.clampDuration(-5) == 20)
        precondition(SpellbreakLimits.clampDuration(1) == 10)
        precondition(SpellbreakLimits.clampDuration(99_999) == 180)
        precondition(SpellbreakLimits.clampInterval(.infinity) == 20)
        precondition(SpellbreakLimits.clampInterval(2) == 15)
        precondition(SpellbreakLimits.clampInterval(500) == 180)
        precondition(TimeInterval.nan.mmss == "0:00")
        precondition(TimeInterval(-10).mmss == "0:00")
        precondition(TimeInterval(425).mmss == "7:05")
        precondition(TimeInterval(75).spokenDuration == "1 minute, 15 seconds")
        print("ok: timing clamps and countdown formatting hold against NaN/overflow")

        // 0b. Notched MacBook geometry: maximized desktop window vs dedicated Full Screen Space
        let notchedScreen = ScreenBusy.ScreenGeometry(
            quartzFrame: CGRect(x: 0, y: 0, width: 1710, height: 1107),
            notchTopInset: 34
        )
        let maximizedWindow: [String: Any] = [
            kCGWindowLayer as String: 0,
            kCGWindowOwnerName as String: "Zen",
            kCGWindowBounds as String: [
                "X": CGFloat(0), "Y": CGFloat(34),
                "Width": CGFloat(1710), "Height": CGFloat(1073)
            ]
        ]
        let finderDesktop: [String: Any] = [
            kCGWindowLayer as String: -2_147_483_603,
            kCGWindowOwnerName as String: "Finder",
            kCGWindowBounds as String: [
                "X": CGFloat(0), "Y": CGFloat(0),
                "Width": CGFloat(1710), "Height": CGFloat(1107)
            ]
        ]
        if ScreenBusy.isScreenCoveredByFullscreenWindow(
            screens: [notchedScreen],
            windows: [maximizedWindow, finderDesktop]
        ) {
            fputs("FAIL: maximized window on notched desktop (with auto-hidden Dock) falsely read as fullscreen\n", stderr)
            exit(1)
        }
        if !ScreenBusy.isScreenCoveredByFullscreenWindow(
            screens: [notchedScreen],
            windows: [maximizedWindow]
        ) {
            fputs("FAIL: native Full Screen Space below camera notch did not read as fullscreen\n", stderr)
            exit(1)
        }
        print("ok: notched MacBook distinguishes maximized desktop window from Full Screen Space")

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
