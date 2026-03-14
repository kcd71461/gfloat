# Drag Handle & Configurable Window Size

## Goal
Add a visible drag handle bar to the floating window so users can reposition it, and make the default window size configurable via Preferences.

## Architecture

The WebViewController's view changes from a bare WKWebView to a vertical stack: a native drag handle bar (24px) on top + WKWebView below. Window dragging is restricted to this handle bar only.

Window size becomes a user preference stored in UserDefaults, with UI controls in the existing PreferencesWindow.

## Components

### 1. DragHandleBar (new NSView subclass in WebViewController)

- Height: 24px fixed
- Background: `#1a1a2e` (matches Gemini dark theme)
- Center: pill indicator — 36x4px, white 30% opacity, cornerRadius 2
- Bottom: 1px separator line, white 8% opacity
- Mouse handling: `mouseDown` + `mouseDragged` → `window?.performDrag(with:)`

### 2. WebViewController changes

- `loadView()`: create container NSView, add DragHandleBar (pinned top, 24px height) + WKWebView (fills remaining space) using Auto Layout
- `self.view = container` instead of `self.view = webView`

### 3. FloatingWindow changes

- `isMovableByWindowBackground = false` (only handle bar allows drag)
- Default size from `Config.shared.windowWidth` x `Config.shared.windowHeight`

### 4. Config changes

- Add `windowWidth: Int` (default 800) with UserDefaults key `"windowWidth"`
- Add `windowHeight: Int` (default 800) with UserDefaults key `"windowHeight"`

### 5. PreferencesWindow changes

- New section below "Hide on deactivate" checkbox: "Window Size"
- Two labeled text fields: Width and Height (NSTextField, numeric only)
- On value change: save to Config, call `onWindowSizeChanged` callback
- Callback wired in AppDelegate to `floatingWindow.setContentSize()` + `center()`

### 6. AppDelegate changes

- Read `Config.shared.windowWidth/Height` for initial `setContentSize`
- Pass `onWindowSizeChanged` callback to PreferencesWindow

## Files Changed

| File | Change |
|------|--------|
| `WebViewController.swift` | Container view with DragHandleBar + WKWebView |
| `FloatingWindow.swift` | `isMovableByWindowBackground = false`, size from Config |
| `Config.swift` | `windowWidth`, `windowHeight` properties |
| `PreferencesWindow.swift` | Width/Height input fields, callback |
| `AppDelegate.swift` | Read Config for size, wire size-change callback |
