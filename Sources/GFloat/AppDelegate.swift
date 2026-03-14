import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: FloatingWindow!
    private var webViewController: WebViewController!
    private var hotkeyManager: HotkeyManager!
    private var statusItem: NSStatusItem!
    private var onboardingWindow: OnboardingWindow?
    private var preferencesWindow: PreferencesWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[GFloat] applicationDidFinishLaunching")

        floatingWindow = FloatingWindow()
        webViewController = WebViewController()
        floatingWindow.contentViewController = webViewController
        floatingWindow.setContentSize(NSSize(width: Config.shared.windowWidth, height: Config.shared.windowHeight))
        floatingWindow.applyVisualStyle()
        NSLog("[GFloat] window frame: \(floatingWindow.frame), isVisible: \(floatingWindow.isVisible)")

        floatingWindow.onDidShow = { [weak self] in
            // Small delay to let WebView settle focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.webViewController.focusPromptInput()
            }
        }

        hotkeyManager = HotkeyManager { [weak self] in
            NSLog("[GFloat] hotkey triggered, window isVisible: \(self?.floatingWindow.isVisible ?? false)")
            self?.floatingWindow.toggle()
        }

        setupMainMenu()
        setupMenuBar()

        let onboarded = Config.shared.hasCompletedOnboarding
        NSLog("[GFloat] hasCompletedOnboarding: \(onboarded)")

        if onboarded {
            startApp()
        } else {
            showOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }

    private func showOnboarding() {
        NSLog("[GFloat] showOnboarding")
        onboardingWindow = OnboardingWindow { [weak self] in
            self?.onboardingWindow = nil
            self?.startApp()
        }
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSLog("[GFloat] onboarding window frame: \(onboardingWindow?.frame ?? .zero), isVisible: \(onboardingWindow?.isVisible ?? false)")
    }

    private func startApp() {
        NSLog("[GFloat] startApp")
        hotkeyManager.register()
        floatingWindow.show()
        NSLog("[GFloat] after show - isVisible: \(floatingWindow.isVisible), frame: \(floatingWindow.frame), level: \(floatingWindow.level.rawValue)")

    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit GFloat", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit menu (required for Cmd+C/V/X/A to work in WebView)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let iconPath = Bundle.main.path(forResource: "menubar-icon", ofType: "png") {
                let icon = NSImage(contentsOfFile: iconPath)
                icon?.isTemplate = false
                icon?.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "GFloat")
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide", action: #selector(toggleWindow), keyEquivalent: "g"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())

        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit GFloat", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func toggleWindow() {
        floatingWindow.toggle()
    }

    @objc private func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow(
                onHotkeyChanged: { [weak self] in
                    self?.hotkeyManager.reregister()
                },
                onWindowSizeChanged: { [weak self] in
                    let w = Config.shared.windowWidth
                    let h = Config.shared.windowHeight
                    self?.floatingWindow.setContentSize(NSSize(width: w, height: h))
                }
            )
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
            sender.state = .off
        } else {
            try? SMAppService.mainApp.register()
            sender.state = .on
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
