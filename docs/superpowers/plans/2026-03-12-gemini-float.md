# Gemini Float Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menubar app that shows a floating Gemini chat window on a global hotkey, hides on ESC, and persists state across show/hide cycles — like Raycast for Gemini.

**Architecture:** Swift Package Manager executable that creates an NSApplication with no dock icon (LSUIElement). A single NSWindow with WKWebView loads gemini.google.com and is toggled via CGEvent-based global hotkey. First-run onboarding guides users through Accessibility permission. Config stored in UserDefaults.

**Tech Stack:** Swift 6, AppKit, WebKit (WKWebView), Carbon (RegisterEventHotKey for global shortcuts), macOS 14+

---

## File Structure

```
GeminiFloat/
├── Package.swift                    # SPM manifest
├── Sources/
│   └── GeminiFloat/
│       ├── main.swift               # Entry point: NSApplication setup
│       ├── AppDelegate.swift        # Menu bar, app lifecycle
│       ├── FloatingWindow.swift     # NSWindow subclass (floating, center, ESC handling)
│       ├── WebViewController.swift  # WKWebView controller loading gemini.google.com
│       ├── HotkeyManager.swift      # Global hotkey registration via Carbon API
│       ├── OnboardingWindow.swift   # First-run accessibility permission guide
│       ├── PreferencesWindow.swift  # Settings: hotkey config
│       └── Config.swift             # UserDefaults wrapper for settings
├── Resources/
│   └── Info.plist                   # LSUIElement=true, app metadata
├── scripts/
│   └── bundle.sh                   # Packages .build output into .app bundle
└── docs/
    └── superpowers/
        └── plans/
            └── 2026-03-12-gemini-float.md
```

---

## Chunk 1: Project Skeleton & Floating Window

### Task 1: Initialize Swift Package

**Files:**
- Create: `Package.swift`
- Create: `Sources/GeminiFloat/main.swift`

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GeminiFloat",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GeminiFloat",
            path: "Sources/GeminiFloat"
        )
    ]
)
```

- [ ] **Step 2: Create minimal main.swift**

```swift
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // No dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 3: Create stub AppDelegate.swift**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("GeminiFloat launched")
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `cd /Users/iscreamarts/workspace/kcd71461/gemini-float && swift build 2>&1`
Expected: Build succeeds, no errors

- [ ] **Step 5: Run and verify**

Run: `cd /Users/iscreamarts/workspace/kcd71461/gemini-float && timeout 3 swift run 2>&1 || true`
Expected: "GeminiFloat launched" printed

---

### Task 2: Floating Window

**Files:**
- Create: `Sources/GeminiFloat/FloatingWindow.swift`
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Create FloatingWindow.swift**

```swift
import AppKit

class FloatingWindow: NSWindow {
    init() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 480
        let windowHeight: CGFloat = 700
        let windowRect = NSRect(
            x: screenFrame.midX - windowWidth / 2,
            y: screenFrame.midY - windowHeight / 2,
            width: windowWidth,
            height: windowHeight
        )

        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        self.backgroundColor = .windowBackgroundColor
    }

    override func cancelOperation(_ sender: Any?) {
        hide()
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        center()
    }

    func hide() {
        orderOut(nil)
    }
}
```

- [ ] **Step 2: Wire window into AppDelegate**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: FloatingWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        floatingWindow = FloatingWindow()
        floatingWindow.show()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 3: WKWebView with Gemini

**Files:**
- Create: `Sources/GeminiFloat/WebViewController.swift`
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Create WebViewController.swift**

```swift
import AppKit
import WebKit

class WebViewController: NSViewController {
    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = self
        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadGemini()
    }

    func loadGemini() {
        guard let url = URL(string: "https://gemini.google.com") else { return }
        webView.load(URLRequest(url: url))
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Open external links in default browser
        if let url = navigationAction.request.url,
           navigationAction.navigationType == .linkActivated,
           !url.host?.contains("gemini.google.com") ?? false {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
```

- [ ] **Step 2: Set WebViewController as window content**

Update AppDelegate:

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: FloatingWindow!
    private var webViewController: WebViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        floatingWindow = FloatingWindow()
        webViewController = WebViewController()
        floatingWindow.contentViewController = webViewController
        floatingWindow.show()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

## Chunk 2: Global Hotkey & Menu Bar

### Task 4: Global Hotkey Manager

**Files:**
- Create: `Sources/GeminiFloat/HotkeyManager.swift`
- Create: `Sources/GeminiFloat/Config.swift`
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Create Config.swift**

```swift
import Foundation
import Carbon

struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultHotkey = HotkeyConfig(
        keyCode: UInt32(kVK_ANSI_G),
        modifiers: UInt32(cmdKey | shiftKey)
    )
}

class Config {
    static let shared = Config()

    private let defaults = UserDefaults.standard
    private let hotkeyKey = "hotkeyConfig"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hotkey: HotkeyConfig {
        get {
            guard let data = defaults.data(forKey: hotkeyKey),
                  let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) else {
                return .defaultHotkey
            }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: hotkeyKey)
            }
        }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: hasCompletedOnboardingKey) }
        set { defaults.set(newValue, forKey: hasCompletedOnboardingKey) }
    }
}
```

- [ ] **Step 2: Create HotkeyManager.swift**

```swift
import Carbon
import AppKit

class HotkeyManager {
    private var hotkeyRef: EventHotKeyRef?
    private var onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
    }

    func register() {
        unregister()

        let config = Config.shared.hotkey
        var hotkeyID = EventHotKeyID(signature: OSType(0x474D_464C), id: 1) // "GMFL"
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.onToggle()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
    }

    func reregister() {
        register()
    }
}
```

- [ ] **Step 3: Wire hotkey into AppDelegate**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: FloatingWindow!
    private var webViewController: WebViewController!
    private var hotkeyManager: HotkeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        floatingWindow = FloatingWindow()
        webViewController = WebViewController()
        floatingWindow.contentViewController = webViewController

        hotkeyManager = HotkeyManager { [weak self] in
            self?.floatingWindow.toggle()
        }
        hotkeyManager.register()

        floatingWindow.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 5: Menu Bar Tray Icon

**Files:**
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Add status bar item to AppDelegate**

Replace AppDelegate with full version including menu bar:

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: FloatingWindow!
    private var webViewController: WebViewController!
    private var hotkeyManager: HotkeyManager!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        floatingWindow = FloatingWindow()
        webViewController = WebViewController()
        floatingWindow.contentViewController = webViewController

        hotkeyManager = HotkeyManager { [weak self] in
            self?.floatingWindow.toggle()
        }
        hotkeyManager.register()

        setupMenuBar()
        floatingWindow.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "Gemini Float")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Gemini", action: #selector(toggleWindow), keyEquivalent: "g"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Gemini Float", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func toggleWindow() {
        floatingWindow.toggle()
    }

    @objc private func showPreferences() {
        // Will be implemented in Task 7
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

## Chunk 3: Onboarding & Preferences

### Task 6: First-Run Onboarding Window

**Files:**
- Create: `Sources/GeminiFloat/OnboardingWindow.swift`
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Create OnboardingWindow.swift**

```swift
import AppKit

class OnboardingWindow: NSWindow {
    private var onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete

        let windowRect = NSRect(x: 0, y: 0, width: 500, height: 400)
        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Welcome to Gemini Float"
        self.isReleasedWhenClosed = false
        self.center()

        setupContent()
    }

    private func setupContent() {
        let contentView = NSView(frame: contentRect(forFrameRect: frame))

        // Title
        let titleLabel = NSTextField(labelWithString: "Welcome to Gemini Float")
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Description
        let descLabel = NSTextField(wrappingLabelWithString:
            "Gemini Float needs Accessibility permission to register the global keyboard shortcut (⌘+Shift+G).\n\n" +
            "Steps:\n" +
            "1. Click \"Open System Settings\" below\n" +
            "2. Find \"Gemini Float\" in the list\n" +
            "3. Toggle it ON\n" +
            "4. Come back here and click \"Continue\"\n\n" +
            "This permission only allows the app to listen for your keyboard shortcut. No other data is accessed."
        )
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.alignment = .left
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)

        // Open Settings button
        let openSettingsButton = NSButton(title: "Open System Settings", target: self, action: #selector(openAccessibilitySettings))
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(openSettingsButton)

        // Continue button
        let continueButton = NSButton(title: "Continue", target: self, action: #selector(completeOnboarding))
        continueButton.bezelStyle = .rounded
        continueButton.keyEquivalent = "\r"
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(continueButton)

        // Status indicator
        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.tag = 100
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            openSettingsButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            openSettingsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -70),

            continueButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            continueButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 70),

            statusLabel.topAnchor.constraint(equalTo: openSettingsButton.bottomAnchor, constant: 15),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])

        self.contentView = contentView
        updateAccessibilityStatus()
    }

    private func updateAccessibilityStatus() {
        guard let statusLabel = contentView?.viewWithTag(100) as? NSTextField else { return }
        let trusted = AXIsProcessTrusted()
        if trusted {
            statusLabel.stringValue = "✓ Accessibility permission granted"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.stringValue = "Accessibility permission not yet granted"
            statusLabel.textColor = .systemOrange
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)

        // Poll for permission change
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.updateAccessibilityStatus()
            if AXIsProcessTrusted() {
                timer.invalidate()
            }
        }
    }

    @objc private func completeOnboarding() {
        Config.shared.hasCompletedOnboarding = true
        close()
        onComplete()
    }
}
```

- [ ] **Step 2: Add onboarding flow to AppDelegate**

Update `applicationDidFinishLaunching` in AppDelegate:

```swift
    private var onboardingWindow: OnboardingWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        floatingWindow = FloatingWindow()
        webViewController = WebViewController()
        floatingWindow.contentViewController = webViewController

        hotkeyManager = HotkeyManager { [weak self] in
            self?.floatingWindow.toggle()
        }

        setupMenuBar()

        if Config.shared.hasCompletedOnboarding {
            startApp()
        } else {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        onboardingWindow = OnboardingWindow { [weak self] in
            self?.onboardingWindow = nil
            self?.startApp()
        }
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func startApp() {
        hotkeyManager.register()
        floatingWindow.show()
    }
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 7: Preferences Window (Hotkey Config)

**Files:**
- Create: `Sources/GeminiFloat/PreferencesWindow.swift`
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Create PreferencesWindow.swift**

```swift
import AppKit
import Carbon

class PreferencesWindow: NSWindow {
    private var hotkeyField: NSTextField!
    private var isRecording = false
    private var recordedKeyCode: UInt32?
    private var recordedModifiers: UInt32?
    private var onHotkeyChanged: (() -> Void)?

    init(onHotkeyChanged: @escaping () -> Void) {
        self.onHotkeyChanged = onHotkeyChanged

        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 200)
        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Preferences"
        self.isReleasedWhenClosed = false
        self.center()

        setupContent()
    }

    private func setupContent() {
        let contentView = NSView(frame: contentRect(forFrameRect: frame))

        let label = NSTextField(labelWithString: "Global Shortcut:")
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        hotkeyField = NSTextField(string: currentHotkeyString())
        hotkeyField.isEditable = false
        hotkeyField.alignment = .center
        hotkeyField.font = .systemFont(ofSize: 16, weight: .medium)
        hotkeyField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hotkeyField)

        let recordButton = NSButton(title: "Record New Shortcut", target: self, action: #selector(startRecording))
        recordButton.bezelStyle = .rounded
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recordButton)

        let resetButton = NSButton(title: "Reset to Default", target: self, action: #selector(resetToDefault))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resetButton)

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -30),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            hotkeyField.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            hotkeyField.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 15),
            hotkeyField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),

            recordButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            recordButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -70),

            resetButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            resetButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 70),
        ])

        self.contentView = contentView
    }

    private func currentHotkeyString() -> String {
        let config = Config.shared.hotkey
        return hotkeyString(keyCode: config.keyCode, modifiers: config.modifiers)
    }

    private func hotkeyString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }

        let keyName = keyCodeToString(keyCode)
        parts.append(keyName)
        return parts.joined()
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String {
        let mapping: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1D: "0", 0x1E: "]", 0x1F: "O",
            0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x28: "K",
            0x2C: "/", 0x2D: "N", 0x2E: "M",
        ]
        return mapping[keyCode] ?? "Key(\(keyCode))"
    }

    @objc private func startRecording() {
        isRecording = true
        hotkeyField.stringValue = "Press new shortcut…"

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecording else { return event }

            let modifiers = event.modifierFlags
            var carbonMods: UInt32 = 0
            if modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
            if modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
            if modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
            if modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }

            // Require at least one modifier
            guard carbonMods != 0 else { return nil }

            let keyCode = UInt32(event.keyCode)
            Config.shared.hotkey = HotkeyConfig(keyCode: keyCode, modifiers: carbonMods)
            self.hotkeyField.stringValue = self.currentHotkeyString()
            self.isRecording = false
            self.onHotkeyChanged?()
            return nil
        }
    }

    @objc private func resetToDefault() {
        Config.shared.hotkey = .defaultHotkey
        hotkeyField.stringValue = currentHotkeyString()
        onHotkeyChanged?()
    }
}
```

- [ ] **Step 2: Wire preferences into AppDelegate**

Add to AppDelegate:

```swift
    private var preferencesWindow: PreferencesWindow?

    @objc private func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow { [weak self] in
                self?.hotkeyManager.reregister()
            }
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

## Chunk 4: App Bundle & Polish

### Task 8: Info.plist and App Bundle Script

**Files:**
- Create: `Resources/Info.plist`
- Create: `scripts/bundle.sh`

- [ ] **Step 1: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Gemini Float</string>
    <key>CFBundleDisplayName</key>
    <string>Gemini Float</string>
    <key>CFBundleIdentifier</key>
    <string>com.gemini-float.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>GeminiFloat</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026</string>
</dict>
</plist>
```

- [ ] **Step 2: Create bundle.sh**

```bash
#!/bin/bash
set -e

APP_NAME="Gemini Float"
BUNDLE_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Build release
swift build -c release

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"

# Create bundle structure
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy executable
cp .build/release/GeminiFloat "${MACOS_DIR}/GeminiFloat"

# Copy Info.plist
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

echo "✓ Built: ${BUNDLE_DIR}"
echo "  Run: open \"${BUNDLE_DIR}\""
```

- [ ] **Step 3: Make script executable and test**

Run: `chmod +x scripts/bundle.sh && cd /Users/iscreamarts/workspace/kcd71461/gemini-float && bash scripts/bundle.sh 2>&1`
Expected: "✓ Built: build/Gemini Float.app"

---

### Task 9: Launch at Login (Optional Menu Item)

**Files:**
- Modify: `Sources/GeminiFloat/AppDelegate.swift`

- [ ] **Step 1: Add login item toggle to menu**

Add to `setupMenuBar()` in AppDelegate, before the Quit item:

```swift
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)
```

Add method:

```swift
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        import ServiceManagement
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
            sender.state = .off
        } else {
            try? SMAppService.mainApp.register()
            sender.state = .on
        }
    }
```

Note: `SMAppService` requires macOS 13+ and only works when running as a proper .app bundle.

- [ ] **Step 2: Build and verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 10: Final Integration & Cleanup

- [ ] **Step 1: Verify complete AppDelegate has all features wired together**
- [ ] **Step 2: Full build**: `swift build -c release 2>&1`
- [ ] **Step 3: Bundle**: `bash scripts/bundle.sh`
- [ ] **Step 4: Test**: `open "build/Gemini Float.app"`
- [ ] **Step 5: Manual verification checklist**:
  - App starts with no dock icon
  - Menu bar icon appears
  - Onboarding window shows on first run
  - Gemini loads in floating window
  - ⌘+Shift+G toggles window
  - ESC hides window
  - Window reappears with same state on toggle
  - Preferences allow hotkey change
