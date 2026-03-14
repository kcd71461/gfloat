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

        self.title = "Welcome to GFloat"
        self.isReleasedWhenClosed = false
        self.center()

        setupContent()
    }

    private func setupContent() {
        let contentView = NSView(frame: contentRect(forFrameRect: frame))

        let titleLabel = NSTextField(labelWithString: "Welcome to GFloat")
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        let descLabel = NSTextField(wrappingLabelWithString:
            "GFloat needs Accessibility permission to register the global keyboard shortcut (\u{2318}+Shift+G).\n\n" +
            "Steps:\n" +
            "1. Click \"Open System Settings\" below\n" +
            "2. Find \"GFloat\" in the list\n" +
            "3. Toggle it ON\n" +
            "4. Come back here and click \"Continue\"\n\n" +
            "This permission only allows the app to listen for your keyboard shortcut. No other data is accessed."
        )
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.alignment = .left
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)

        let openSettingsButton = NSButton(title: "Open System Settings", target: self, action: #selector(openAccessibilitySettings))
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(openSettingsButton)

        let continueButton = NSButton(title: "Continue", target: self, action: #selector(completeOnboarding))
        continueButton.bezelStyle = .rounded
        continueButton.keyEquivalent = "\r"
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(continueButton)

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
            statusLabel.stringValue = "Accessibility permission granted"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.stringValue = "Accessibility permission not yet granted"
            statusLabel.textColor = .systemOrange
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.updateAccessibilityStatus()
            if AXIsProcessTrusted() {
                timer.invalidate()
            }
        }
    }

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
}
