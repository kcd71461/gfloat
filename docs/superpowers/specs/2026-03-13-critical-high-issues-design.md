# GFloat Critical/High Issues Fix — Design Spec

**Date:** 2026-03-13
**Scope:** Critical and High severity issues from UI/UX, Legal, and Docs reviews

---

## 1. Window Position & Behavior

### 1.1 Window Position Memory (#1, #8)
- Remove all 4 `center()` calls:
  1. `FloatingWindow.swift` `init()` (line 23)
  2. `FloatingWindow.swift` `show()` (line 54)
  3. `AppDelegate.swift` `applicationDidFinishLaunching` (line 19)
  4. `AppDelegate.swift` Preferences `onWindowSizeChanged` callback (line 141)
- Position persistence: add new `windowX: Int?` and `windowY: Int?` properties to `Config.swift` (new additions, default nil). Save/restore window origin via these Config properties. Do NOT use `setFrameAutosaveName` — it persists both position and size, conflicting with the existing Config-based `windowWidth`/`windowHeight` persistence
- On first launch (windowX/windowY are nil): call `center()` once
- On window size change in Preferences: keep current origin, only adjust size
- Save position on `windowDidMove` notification

### 1.2 ESC Key Handling (#3)
- Current: `sendEvent` intercepts ESC unconditionally, calls `hide()`
- Change: Double-ESC to hide (two presses within 0.5s). First ESC passes through to WebView for closing Gemini internal modals/search
- Track `lastEscTime: Date?` property on `FloatingWindow`
- On first ESC: call `super.sendEvent(event)` to forward the event to WebView, then record `lastEscTime`
- On second ESC within 0.5s: call `hide()` and reset `lastEscTime` to nil so subsequent presses start a fresh sequence

### 1.3 Auto-hide Conflict with Preferences (#7)
- In `hideOnDeactivate` observer, skip hiding when Preferences or Onboarding windows are open
- Detection: check `NSApp.windows.contains(where: { $0 is PreferencesWindow || $0 is OnboardingWindow })` — avoids coupling FloatingWindow to AppDelegate
- Set Preferences window level to `.floating + 1` in `PreferencesWindow.init()` so it appears above the floating window

**Files:** `FloatingWindow.swift`, `AppDelegate.swift`, `Config.swift`

---

## 2. Onboarding & Drag Handle UX

### 2.1 Onboarding Permission Check (#4)
- In `completeOnboarding()`, check `AXIsProcessTrusted()`
- If false: show NSAlert warning that hotkey won't work without permission
- Confirm → proceed, Cancel → stay on onboarding

### 2.2 Drag Handle Discoverability (#5)
- Pill indicator size: 36x4px → 48x5px, opacity 0.3 → 0.5
- Add `resetCursorRects` with `openHand` cursor on hover
- Change to `closedHand` cursor during drag: use `NSCursor.closedHand.push()` before `performDrag(with:)` and `NSCursor.pop()` after it returns
- Note: `DragHandleBar` is a private class within `WebViewController.swift`

**Files:** `OnboardingWindow.swift`, `WebViewController.swift` (DragHandleBar)

---

## 3. WebView Stability

### 3.1 focusPromptInput Retry Logic (#6)
- Current: `AppDelegate` calls `focusPromptInput()` after 0.3s fixed delay, single attempt
- Change: retry logic self-contained within `focusPromptInput()` in `WebViewController.swift`. AppDelegate calls it with a single 0.3s delay as before, but internally the method makes up to 3 total attempts (1st at 0s, 2nd at 0.3s, 3rd at 0.6s after previous) when `evaluateJavaScript` result indicates selector not found
- Fail silently after all 3 attempts (non-critical feature)

**Files:** `WebViewController.swift`

---

## 4. Legal & Policy

### 4.1 User Agent Spoofing Removal (#9, #11)
- Remove custom Safari UA string from `WebViewController.swift`
- Use WKWebView default UA
- This is a manual testing sequence during implementation: first remove the custom UA, test manually. If Gemini returns an unsupported-browser page, then append `GFloat/1.0` to the default UA string. If still blocked: document in README and track API migration as separate issue

### 4.2 Trademark Disclaimer (#10)
- Add Disclaimer section to bottom of both README.md and README.ko.md:
  - EN: "This project is not affiliated with, endorsed by, or associated with Google LLC. Google and Gemini are trademarks of Google LLC."
  - KO: Korean translation of the same

**Files:** `WebViewController.swift`, `README.md`, `README.ko.md`

---

## 5. Documentation Fixes

### 5.1 README Corrections (#12, #13)
- Fix git clone URL: `gemini-float` → `https://github.com/kcd71461/gfloat.git`, directory `gfloat` (both READMEs)
- Fix project structure tree root: `gemini-float/` → `gfloat/` (both READMEs)
- Comment out `demo.gif` reference (file does not exist)
- Update ESC shortcut description in both READMEs to reflect double-ESC behavior (changed in Section 1.2)

**Files:** `README.md`, `README.ko.md`

---

## 6. VoiceOver Accessibility

### 6.1 Basic Accessibility Labels (#2)
- `FloatingWindow`: `setAccessibilityLabel("GFloat - Gemini Chat")`
- `DragHandleBar`: `setAccessibilityLabel("Drag to move window")`, `setAccessibilityRole(.handle)`
- Scope: basic identification only, not full VoiceOver support

**Files:** `FloatingWindow.swift`, `WebViewController.swift`

---

## Out of Scope
- Medium/Low severity issues (deferred to follow-up)
- Gemini API migration (separate project)
- Full VoiceOver audit
- Loading indicators, network error handling
- CONTRIBUTING.md, CHANGELOG.md, CI/CD
