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

    // Prevent ESC from closing the window via AppKit's default responder chain.
    // Our double-ESC logic in sendEvent handles hiding instead.
    override func cancelOperation(_ sender: Any?) {}

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
        if event.type == .keyDown && event.keyCode == 53 && !event.isARepeat {
            if Config.shared.doubleEscToHide {
                let now = Date()
                if let last = lastEscTime, now.timeIntervalSince(last) < 0.5 {
                    lastEscTime = nil
                    hide()
                    return
                }
                lastEscTime = now
                super.sendEvent(event)
                return
            } else {
                hide()
                return
            }
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
