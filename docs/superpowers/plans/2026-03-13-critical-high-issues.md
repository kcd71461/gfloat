# Critical/High Issues Fix — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 13 Critical/High severity issues from UI/UX, Legal, and Docs reviews.

**Architecture:** Each task modifies 1-3 files with focused changes. Tasks are ordered by dependency — Config changes first (needed by window position), then FloatingWindow, then other files, then docs last.

**Tech Stack:** Swift, AppKit, WKWebView, macOS 14+

**Spec:** `docs/superpowers/specs/2026-03-13-critical-high-issues-design.md`

---

## Chunk 1: Code Changes

### Task 1: Add window position properties to Config

**Files:**
- Modify: `Sources/GFloat/Config.swift:51-65`

- [ ] **Step 1: Add windowX and windowY properties**

Add after the `windowHeight` property (line 65):

```swift
var windowX: Int? {
    get {
        if defaults.object(forKey: "windowX") == nil { return nil }
        return defaults.integer(forKey: "windowX")
    }
    set {
        if let v = newValue {
            defaults.set(v, forKey: "windowX")
        } else {
            defaults.removeObject(forKey: "windowX")
        }
    }
}

var windowY: Int? {
    get {
        if defaults.object(forKey: "windowY") == nil { return nil }
        return defaults.integer(forKey: "windowY")
    }
    set {
        if let v = newValue {
            defaults.set(v, forKey: "windowY")
        } else {
            defaults.removeObject(forKey: "windowY")
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/GFloat/Config.swift
git commit -m "feat: add windowX/windowY position persistence to Config"
```

---

### Task 2: Fix FloatingWindow — position memory, double-ESC, auto-hide conflict, accessibility

**Files:**
- Modify: `Sources/GFloat/FloatingWindow.swift`

- [ ] **Step 1: Replace the entire FloatingWindow implementation**

Replace `FloatingWindow.swift` with:

```swift
import AppKit

class FloatingWindow: NSWindow {
    var onDidShow: (() -> Void)?
    private var deactivateObserver: Any?
    private var moveObserver: Any?
    private var lastEscTime: Date?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 800),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        self.isMovableByWindowBackground = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        self.hasShadow = true
        self.minSize = NSSize(width: 320, height: 400)

        setAccessibilityLabel("GFloat - Gemini Chat")

        setupDeactivateObserver()
        setupMoveObserver()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func applyVisualStyle() {
        guard let cv = contentView else { return }
        cv.wantsLayer = true
        cv.layer?.cornerRadius = 12
        cv.layer?.masksToBounds = true
        cv.layer?.borderWidth = 0.5
        cv.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        invalidateShadow()
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown && event.keyCode == 53 {
            let now = Date()
            if let last = lastEscTime, now.timeIntervalSince(last) < 0.5 {
                lastEscTime = nil
                hide()
                return
            }
            lastEscTime = now
            super.sendEvent(event)
            return
        }
        super.sendEvent(event)
    }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        restorePosition()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        invalidateShadow()
        onDidShow?()
    }

    func hide() {
        orderOut(nil)
    }

    private func restorePosition() {
        if let x = Config.shared.windowX, let y = Config.shared.windowY {
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            center()
        }
    }

    private func setupDeactivateObserver() {
        deactivateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.isVisible, Config.shared.hideOnDeactivate else { return }
            let hasOtherWindows = NSApp.windows.contains(where: { $0 is PreferencesWindow || $0 is OnboardingWindow })
            if hasOtherWindows { return }
            self.hide()
        }
    }

    private func setupMoveObserver() {
        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Config.shared.windowX = Int(self.frame.origin.x)
            Config.shared.windowY = Int(self.frame.origin.y)
        }
    }

    deinit {
        if let observer = deactivateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = moveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

Key changes:
- Removed `center()` from `init()`
- Added `lastEscTime` for double-ESC: first ESC forwards to WebView via `super.sendEvent`, second ESC within 0.5s calls `hide()`
- Added `restorePosition()` in `show()` — restores from Config or centers on first launch
- Added `setupMoveObserver()` to save position on every move
- Auto-hide skips when PreferencesWindow or OnboardingWindow is open
- Added `setAccessibilityLabel("GFloat - Gemini Chat")`

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/GFloat/FloatingWindow.swift
git commit -m "feat: position memory, double-ESC, auto-hide fix, accessibility label"
```

---

### Task 3: Fix AppDelegate — remove center() calls, keep position on resize

**Files:**
- Modify: `Sources/GFloat/AppDelegate.swift:19,141`

- [ ] **Step 1: Remove center() in applicationDidFinishLaunching**

Remove line 19 (`floatingWindow.center()`) from `applicationDidFinishLaunching`. The window's `show()` → `restorePosition()` now handles positioning.

- [ ] **Step 2: Remove center() in onWindowSizeChanged callback**

In the `showPreferences()` method, remove `self?.floatingWindow.center()` from the `onWindowSizeChanged` callback (line 141). Keep only the `setContentSize` call.

- [ ] **Step 3: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Sources/GFloat/AppDelegate.swift
git commit -m "fix: remove center() calls — window position now persisted"
```

---

### Task 4: Fix WebViewController — UA removal, focus retry, drag handle, accessibility

**Files:**
- Modify: `Sources/GFloat/WebViewController.swift`

- [ ] **Step 1: Remove User Agent spoofing**

Delete line 21:
```swift
webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
```

- [ ] **Step 2: Replace focusPromptInput with retry logic**

Replace the `focusPromptInput()` method (lines 52-76) with:

```swift
func focusPromptInput(attempt: Int = 1) {
    let maxAttempts = 3
    let js = """
    (function() {
        const selectors = [
            '.ql-editor[contenteditable="true"]',
            'div[contenteditable="true"][role="textbox"]',
            'div[contenteditable="true"]',
            'textarea',
            'input[type="text"]'
        ];
        for (const sel of selectors) {
            const el = document.querySelector(sel);
            if (el && el.offsetParent !== null) {
                el.focus();
                return true;
            }
        }
        return false;
    })()
    """
    webView.evaluateJavaScript(js) { [weak self] result, _ in
        let found = result as? Bool ?? false
        NSLog("[GFloat] focusPromptInput attempt \(attempt)/\(maxAttempts): \(found)")
        if !found && attempt < maxAttempts {
            let delay = 0.3 * Double(attempt)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self?.focusPromptInput(attempt: attempt + 1)
            }
        }
    }
}
```

- [ ] **Step 3: Update DragHandleBar — pill size, opacity, cursors, accessibility**

Replace the `DragHandleBar` class (lines 115-154) with:

```swift
private class DragHandleBar: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0).cgColor

        setAccessibilityLabel("Drag to move window")
        setAccessibilityRole(.handle)

        // Pill indicator
        let pill = NSView()
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
        pill.layer?.cornerRadius = 2.5
        pill.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pill)

        // Bottom separator
        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sep)

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: centerYAnchor),
            pill.widthAnchor.constraint(equalToConstant: 48),
            pill.heightAnchor.constraint(equalToConstant: 5),

            sep.leadingAnchor.constraint(equalTo: leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.closedHand.push()
        window?.performDrag(with: event)
        NSCursor.pop()
    }
}
```

Changes: pill 36x4→48x5, opacity 0.3→0.5, cornerRadius 2→2.5, `resetCursorRects` with openHand, closedHand push/pop around performDrag, accessibility label and role.

- [ ] **Step 4: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 5: Manual test — UA removal**

Run: `swift build -c release && bash scripts/bundle.sh && open build/GFloat.app`

Check if Gemini loads normally without the custom UA. If it shows an unsupported browser page, add to `loadView()` after creating the webView:
```swift
webView.customUserAgent = (webView.value(forKey: "userAgent") as? String ?? "") + " GFloat/1.0"
```

- [ ] **Step 6: Commit**

```bash
git add Sources/GFloat/WebViewController.swift
git commit -m "feat: remove UA spoofing, add focus retry, improve drag handle UX"
```

---

### Task 5: Fix OnboardingWindow — permission check before continue

**Files:**
- Modify: `Sources/GFloat/OnboardingWindow.swift:112-116`

- [ ] **Step 1: Add permission check to completeOnboarding**

Replace the `completeOnboarding()` method (lines 112-116) with:

```swift
@objc private func completeOnboarding() {
    if !AXIsProcessTrusted() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Without Accessibility permission, the global hotkey (Cmd+Shift+G) will not work. You can grant it later in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Continue Anyway")
        alert.addButton(withTitle: "Go Back")
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            return
        }
    }
    Config.shared.hasCompletedOnboarding = true
    close()
    onComplete()
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/GFloat/OnboardingWindow.swift
git commit -m "feat: warn user when continuing onboarding without accessibility permission"
```

---

### Task 6: Fix PreferencesWindow — set floating level

**Files:**
- Modify: `Sources/GFloat/PreferencesWindow.swift:25-27`

- [ ] **Step 1: Set window level above floating window**

In `PreferencesWindow.init()`, after `self.center()` (line 27), add:

```swift
self.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1 | tail -5`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/GFloat/PreferencesWindow.swift
git commit -m "fix: preferences window appears above floating window"
```

---

## Chunk 2: Documentation Changes

### Task 7: Fix README.md — URLs, project name, demo.gif, ESC, disclaimer

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Comment out demo.gif (line 5)**

```markdown
<!-- ![GFloat Demo](assets/demo.gif) -->
```

- [ ] **Step 2: Fix git clone URL (lines 29-30)**

```markdown
git clone https://github.com/kcd71461/gfloat.git
cd gfloat
```

- [ ] **Step 3: Update ESC shortcut in keyboard table (line 54)**

```markdown
| `ESC` `ESC` | Hide window (double-press) |
```

- [ ] **Step 4: Fix project structure tree root (line 85)**

```markdown
gfloat/
```

- [ ] **Step 5: Add Disclaimer section before closing**

Add after the License section (after line 134):

```markdown

## Disclaimer

This project is not affiliated with, endorsed by, or associated with Google LLC. Google and Gemini are trademarks of Google LLC.
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: fix README — URLs, ESC description, disclaimer"
```

---

### Task 8: Fix README.ko.md — same corrections in Korean

**Files:**
- Modify: `README.ko.md`

- [ ] **Step 1: Comment out demo.gif (line 5)**

```markdown
<!-- ![GFloat 데모](assets/demo.gif) -->
```

- [ ] **Step 2: Fix git clone URL (lines 29-30)**

```markdown
git clone https://github.com/kcd71461/gfloat.git
cd gfloat
```

- [ ] **Step 3: Update ESC shortcut in keyboard table (line 54)**

```markdown
| `ESC` `ESC` | 창 숨기기 (두 번 누르기) |
```

- [ ] **Step 4: Fix project structure tree root (line 85)**

```markdown
gfloat/
```

- [ ] **Step 5: Add Disclaimer section before closing**

Add after the License section (after line 134):

```markdown

## 면책 조항

이 프로젝트는 Google LLC와 관련이 없으며, Google LLC의 후원이나 승인을 받지 않았습니다. Google 및 Gemini는 Google LLC의 상표입니다.
```

- [ ] **Step 6: Commit**

```bash
git add README.ko.md
git commit -m "docs: fix README.ko — URLs, ESC description, disclaimer"
```

---

## Chunk 3: Final Verification

### Task 9: Full build and manual smoke test

- [ ] **Step 1: Clean build**

```bash
swift package clean && swift build -c release
```

Expected: `Build complete!`

- [ ] **Step 2: Bundle and launch**

```bash
bash scripts/bundle.sh && open build/GFloat.app
```

- [ ] **Step 3: Manual smoke test checklist**

Verify each fix:
1. **Window position**: Move window, hide with hotkey, show again → should appear at last position (not center)
2. **ESC double-press**: Press ESC once → nothing happens to window. Press ESC twice quickly → window hides
3. **Auto-hide + Preferences**: Open Preferences (Cmd+,) → floating window should NOT hide when Preferences gets focus. Preferences should appear above floating window.
4. **Drag handle**: Hover over drag bar → openHand cursor. Drag → closedHand cursor. Pill should be more visible than before.
5. **Onboarding**: Reset onboarding (`defaults delete com.gfloat.app hasCompletedOnboarding`), relaunch. Click Continue without permission → should show warning alert.
6. **Gemini loads**: Verify Gemini loads correctly without custom UA.
7. **Copy/paste**: Cmd+C/V still works in the WebView (Edit menu preserved).
8. **Focus**: Show window → Gemini input should get focus (may retry up to 3 times).

- [ ] **Step 4: Final commit if any adjustments needed**
