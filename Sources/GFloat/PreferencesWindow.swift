import AppKit
import Carbon

class PreferencesWindow: NSWindow {
    private var hotkeyField: NSTextField!
    private var isRecording = false
    private var eventMonitor: Any?
    private var widthField: NSTextField!
    private var heightField: NSTextField!
    private var onHotkeyChanged: (() -> Void)?
    private var onWindowSizeChanged: (() -> Void)?

    init(onHotkeyChanged: @escaping () -> Void, onWindowSizeChanged: @escaping () -> Void) {
        self.onHotkeyChanged = onHotkeyChanged
        self.onWindowSizeChanged = onWindowSizeChanged

        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 360)
        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Preferences"
        self.isReleasedWhenClosed = false
        self.center()
        self.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)

        setupContent()
    }

    private func setupContent() {
        let contentView = NSView(frame: contentRect(forFrameRect: frame))

        // Hotkey section
        let hotkeyLabel = NSTextField(labelWithString: "Global Shortcut:")
        hotkeyLabel.font = .systemFont(ofSize: 14)
        hotkeyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hotkeyLabel)

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

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        // Hide on deactivate toggle
        let hideCheckbox = NSButton(checkboxWithTitle: "Hide window when switching to other apps", target: self, action: #selector(toggleHideOnDeactivate(_:)))
        hideCheckbox.state = Config.shared.hideOnDeactivate ? .on : .off
        hideCheckbox.font = .systemFont(ofSize: 13)
        hideCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hideCheckbox)

        // Double-ESC toggle
        let doubleEscCheckbox = NSButton(checkboxWithTitle: "Require double-press ESC to hide window", target: self, action: #selector(toggleDoubleEsc(_:)))
        doubleEscCheckbox.state = Config.shared.doubleEscToHide ? .on : .off
        doubleEscCheckbox.font = .systemFont(ofSize: 13)
        doubleEscCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(doubleEscCheckbox)

        // Separator 2
        let separator2 = NSBox()
        separator2.boxType = .separator
        separator2.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator2)

        // Window size section
        let sizeLabel = NSTextField(labelWithString: "Window Size:")
        sizeLabel.font = .systemFont(ofSize: 14)
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sizeLabel)

        let wLabel = NSTextField(labelWithString: "W")
        wLabel.font = .systemFont(ofSize: 12)
        wLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(wLabel)

        widthField = NSTextField(string: "\(Config.shared.windowWidth)")
        widthField.alignment = .center
        widthField.font = .systemFont(ofSize: 14)
        widthField.translatesAutoresizingMaskIntoConstraints = false
        widthField.delegate = self
        contentView.addSubview(widthField)

        let xLabel = NSTextField(labelWithString: "\u{00D7}")
        xLabel.font = .systemFont(ofSize: 14)
        xLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(xLabel)

        let hLabel = NSTextField(labelWithString: "H")
        hLabel.font = .systemFont(ofSize: 12)
        hLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hLabel)

        heightField = NSTextField(string: "\(Config.shared.windowHeight)")
        heightField.alignment = .center
        heightField.font = .systemFont(ofSize: 14)
        heightField.translatesAutoresizingMaskIntoConstraints = false
        heightField.delegate = self
        contentView.addSubview(heightField)

        NSLayoutConstraint.activate([
            hotkeyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            hotkeyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            hotkeyField.centerYAnchor.constraint(equalTo: hotkeyLabel.centerYAnchor),
            hotkeyField.leadingAnchor.constraint(equalTo: hotkeyLabel.trailingAnchor, constant: 15),
            hotkeyField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),

            recordButton.topAnchor.constraint(equalTo: hotkeyLabel.bottomAnchor, constant: 20),
            recordButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -70),

            resetButton.topAnchor.constraint(equalTo: hotkeyLabel.bottomAnchor, constant: 20),
            resetButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 70),

            separator.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            hideCheckbox.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 15),
            hideCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            doubleEscCheckbox.topAnchor.constraint(equalTo: hideCheckbox.bottomAnchor, constant: 8),
            doubleEscCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            separator2.topAnchor.constraint(equalTo: doubleEscCheckbox.bottomAnchor, constant: 15),
            separator2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            sizeLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 15),
            sizeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),

            wLabel.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            wLabel.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant: 15),

            widthField.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            widthField.leadingAnchor.constraint(equalTo: wLabel.trailingAnchor, constant: 4),
            widthField.widthAnchor.constraint(equalToConstant: 60),

            xLabel.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            xLabel.leadingAnchor.constraint(equalTo: widthField.trailingAnchor, constant: 8),

            hLabel.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            hLabel.leadingAnchor.constraint(equalTo: xLabel.trailingAnchor, constant: 8),

            heightField.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            heightField.leadingAnchor.constraint(equalTo: hLabel.trailingAnchor, constant: 4),
            heightField.widthAnchor.constraint(equalToConstant: 60),
        ])

        self.contentView = contentView
    }

    @objc private func toggleHideOnDeactivate(_ sender: NSButton) {
        Config.shared.hideOnDeactivate = sender.state == .on
    }

    @objc private func toggleDoubleEsc(_ sender: NSButton) {
        Config.shared.doubleEscToHide = sender.state == .on
    }

    private func currentHotkeyString() -> String {
        let config = Config.shared.hotkey
        return hotkeyString(keyCode: config.keyCode, modifiers: config.modifiers)
    }

    private func hotkeyString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }

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
        hotkeyField.stringValue = "Press new shortcut..."

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecording else { return event }

            let modifiers = event.modifierFlags
            var carbonMods: UInt32 = 0
            if modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
            if modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
            if modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
            if modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }

            guard carbonMods != 0 else { return nil }

            let keyCode = UInt32(event.keyCode)
            Config.shared.hotkey = HotkeyConfig(keyCode: keyCode, modifiers: carbonMods)
            self.hotkeyField.stringValue = self.currentHotkeyString()
            self.isRecording = false

            if let monitor = self.eventMonitor {
                NSEvent.removeMonitor(monitor)
                self.eventMonitor = nil
            }

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

extension PreferencesWindow: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        let value = max(320, Int(field.stringValue) ?? 0)
        if field === widthField {
            Config.shared.windowWidth = value
            field.stringValue = "\(value)"
        } else if field === heightField {
            Config.shared.windowHeight = value
            field.stringValue = "\(value)"
        }
        onWindowSizeChanged?()
    }
}
