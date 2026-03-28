# Pin Mode & Navigation Buttons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add pin mode (keep window visible when losing focus) and home/refresh navigation buttons to the drag handle bar.

**Architecture:** Add `isPinned` state to `FloatingWindow` with `nonactivatingPanel` styleMask toggling. Restructure `DragHandleBar` layout into 3 zones (left buttons, center pill, right pin button). Wire button actions through a delegate protocol back to `WebViewController`.

**Tech Stack:** Swift, AppKit (NSPanel, NSButton, SF Symbols), WebKit

---

### File Structure

| File | Role |
|------|------|
| `Sources/GFloat/FloatingWindow.swift` | Add `isPinned` property, `setPin(_:)` method, styleMask toggling |
| `Sources/GFloat/WebViewController.swift` | Restructure `DragHandleBar` with 3-zone layout, add delegate protocol, wire button actions |
| `Sources/GFloat/AppDelegate.swift` | Guard `didResignActive` hide logic against pin state |

---

### Task 1: Add Pin Mode to FloatingWindow

**Files:**
- Modify: `Sources/GFloat/FloatingWindow.swift`

- [ ] **Step 1: Add `isPinned` property and `setPin(_:)` method**

In `FloatingWindow`, add the pin state and toggling logic after the `lastEscTime` property:

```swift
private(set) var isPinned: Bool = false

func setPin(_ pinned: Bool) {
    isPinned = pinned
    if pinned {
        styleMask.insert(.nonactivatingPanel)
    } else {
        styleMask.remove(.nonactivatingPanel)
    }
}
```

- [ ] **Step 2: Change `FloatingWindow` from `NSWindow` to `NSPanel`**

`nonactivatingPanel` is an `NSPanel` style mask. Change the class declaration:

```swift
class FloatingWindow: NSPanel {
```

And update `init()` to use `NSPanel`-compatible initialization (the current `super.init(...)` call stays the same since `NSPanel` inherits from `NSWindow`).

- [ ] **Step 3: Guard deactivate observer against pin state**

In `setupDeactivateObserver()`, add pin check to the guard:

```swift
guard let self = self, self.isVisible, Config.shared.hideOnDeactivate, !self.isPinned else { return }
```

- [ ] **Step 4: Reset pin on hide**

In the `hide()` method, reset pin state:

```swift
func hide() {
    if isPinned {
        setPin(false)
    }
    orderOut(nil)
}
```

- [ ] **Step 5: Build and verify**

Run: `cd /Users/kimchangdeog/workspace/github/gfloat && swift build 2>&1`
Expected: Build succeeds with no errors.

- [ ] **Step 6: Commit**

```bash
git add Sources/GFloat/FloatingWindow.swift
git commit -m "feat: add pin mode to FloatingWindow with nonactivatingPanel toggling"
```

---

### Task 2: Restructure DragHandleBar with 3-Zone Layout and Buttons

**Files:**
- Modify: `Sources/GFloat/WebViewController.swift`

- [ ] **Step 1: Add `DragHandleBarDelegate` protocol**

Add above the `DragHandleBar` class:

```swift
protocol DragHandleBarDelegate: AnyObject {
    func dragHandleBarDidTapHome(_ bar: DragHandleBar)
    func dragHandleBarDidTapRefresh(_ bar: DragHandleBar)
    func dragHandleBarDidTapPin(_ bar: DragHandleBar)
}
```

- [ ] **Step 2: Rewrite `DragHandleBar` with 3-zone layout**

Replace the entire `DragHandleBar` class with:

```swift
class DragHandleBar: NSView {
    weak var delegate: DragHandleBarDelegate?
    private let pinButton: NSButton

    override init(frame: NSRect) {
        pinButton = NSButton(frame: .zero)
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0).cgColor

        setAccessibilityLabel("Drag to move window")
        setAccessibilityRole(.handle)

        // Left buttons: Home, Refresh
        let homeButton = makeButton(symbolName: "house", accessibilityLabel: "Home", action: #selector(homeTapped))
        let refreshButton = makeButton(symbolName: "arrow.clockwise", accessibilityLabel: "Refresh", action: #selector(refreshTapped))

        let leftStack = NSStackView(views: [homeButton, refreshButton])
        leftStack.orientation = .horizontal
        leftStack.spacing = 4
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftStack)

        // Center: Pill indicator
        let pill = NSView()
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
        pill.layer?.cornerRadius = 2.5
        pill.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pill)

        // Right: Pin button
        configurePinButton(symbolName: "pin", accessibilityLabel: "Pin window", action: #selector(pinTapped))
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pinButton)

        // Bottom separator
        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sep)

        NSLayoutConstraint.activate([
            // Left stack
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Center pill
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: centerYAnchor),
            pill.widthAnchor.constraint(equalToConstant: 48),
            pill.heightAnchor.constraint(equalToConstant: 5),

            // Right pin button
            pinButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            pinButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Bottom separator
            sep.leadingAnchor.constraint(equalTo: leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func updatePinIcon(isPinned: Bool) {
        let symbolName = isPinned ? "pin.fill" : "pin"
        pinButton.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: isPinned ? "Unpin window" : "Pin window")
    }

    private func makeButton(symbolName: String, accessibilityLabel: String, action: Selector) -> NSButton {
        let button = NSButton(frame: .zero)
        configurePlainButton(button, symbolName: symbolName, accessibilityLabel: accessibilityLabel, action: action)
        return button
    }

    private func configurePinButton(symbolName: String, accessibilityLabel: String, action: Selector) {
        configurePlainButton(pinButton, symbolName: symbolName, accessibilityLabel: accessibilityLabel, action: action)
    }

    private func configurePlainButton(_ button: NSButton, symbolName: String, accessibilityLabel: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        button.bezelStyle = .inline
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.contentTintColor = .white.withAlphaComponent(0.7)
        button.target = self
        button.action = action
        button.setAccessibilityLabel(accessibilityLabel)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 20),
            button.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    @objc private func homeTapped() { delegate?.dragHandleBarDidTapHome(self) }
    @objc private func refreshTapped() { delegate?.dragHandleBarDidTapRefresh(self) }
    @objc private func pinTapped() { delegate?.dragHandleBarDidTapPin(self) }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        // Don't drag if click was on a button
        let location = convert(event.locationInWindow, from: nil)
        for subview in subviews {
            if subview is NSButton || subview is NSStackView {
                if subview.frame.contains(location) { return }
            }
        }
        NSCursor.closedHand.push()
        window?.performDrag(with: event)
        NSCursor.pop()
    }
}
```

Note: Change `DragHandleBar` from `private class` to `class` (remove `private`) since the delegate protocol references it publicly.

- [ ] **Step 3: Build and verify**

Run: `cd /Users/kimchangdeog/workspace/github/gfloat && swift build 2>&1`
Expected: Build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/GFloat/WebViewController.swift
git commit -m "feat: restructure DragHandleBar with home, refresh, and pin buttons"
```

---

### Task 3: Wire Button Actions in WebViewController

**Files:**
- Modify: `Sources/GFloat/WebViewController.swift`

- [ ] **Step 1: Store handleBar reference and conform to delegate**

Add a property to `WebViewController`:

```swift
private var handleBar: DragHandleBar!
```

In `loadView()`, replace `let handleBar = DragHandleBar()` with:

```swift
handleBar = DragHandleBar()
handleBar.delegate = self
```

- [ ] **Step 2: Implement `DragHandleBarDelegate`**

Add an extension at the bottom of the file:

```swift
extension WebViewController: DragHandleBarDelegate {
    func dragHandleBarDidTapHome(_ bar: DragHandleBar) {
        loadGemini()
    }

    func dragHandleBarDidTapRefresh(_ bar: DragHandleBar) {
        webView.reload()
    }

    func dragHandleBarDidTapPin(_ bar: DragHandleBar) {
        guard let floatingWindow = view.window as? FloatingWindow else { return }
        let newPinState = !floatingWindow.isPinned
        floatingWindow.setPin(newPinState)
        handleBar.updatePinIcon(isPinned: newPinState)
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `cd /Users/kimchangdeog/workspace/github/gfloat && swift build 2>&1`
Expected: Build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/GFloat/WebViewController.swift
git commit -m "feat: wire home, refresh, and pin button actions"
```

---

### Task 4: Build, Run, and Manual Verification

**Files:** None (verification only)

- [ ] **Step 1: Full build**

Run: `cd /Users/kimchangdeog/workspace/github/gfloat && swift build 2>&1`
Expected: Build succeeds with no errors.

- [ ] **Step 2: Run the app**

Run: `cd /Users/kimchangdeog/workspace/github/gfloat && .build/debug/GFloat &`

- [ ] **Step 3: Manual verification checklist**

Verify:
1. Drag handle bar shows home (left), refresh (middle-left), pill (center), pin (right)
2. Home button loads gemini.google.com
3. Refresh button reloads current page
4. Pin button toggles icon between `pin` and `pin.fill`
5. When pinned, switching to another app keeps gfloat window visible
6. When unpinned, switching to another app hides gfloat window
7. Double-ESC hides window and resets pin state
8. Drag still works on non-button areas of the handle bar
