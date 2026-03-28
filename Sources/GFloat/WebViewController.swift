import AppKit
import WebKit

class WebViewController: NSViewController {
    private var webView: WKWebView!
    private var handleBar: DragHandleBar!

    override func loadView() {
        let container = NSView()

        // Drag handle bar
        handleBar = DragHandleBar()
        handleBar.delegate = self
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(handleBar)

        // WebView
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)

        NSLayoutConstraint.activate([
            handleBar.topAnchor.constraint(equalTo: container.topAnchor),
            handleBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            handleBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            handleBar.heightAnchor.constraint(equalToConstant: 24),

            webView.topAnchor.constraint(equalTo: handleBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadGemini()
    }

    func loadGemini() {
        guard let url = URL(string: "https://gemini.google.com") else { return }
        webView.load(URLRequest(url: url))
    }

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

    private func isAllowedDomain(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        let allowed = [
            "gemini.google.com",
            "accounts.google.com",
            "myaccount.google.com",
            "login.google.com",
            "accounts.youtube.com",
            "ssl.gstatic.com",
            "apis.google.com",
            "www.google.com",
            "oauth2.googleapis.com",
        ]
        return allowed.contains(where: { host.hasSuffix($0) })
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if isAllowedDomain(url) {
                decisionHandler(.allow)
                return
            }
            // Open non-allowed domains in external browser
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - Drag Handle Bar Delegate

protocol DragHandleBarDelegate: AnyObject {
    func dragHandleBarDidTapHome(_ bar: DragHandleBar)
    func dragHandleBarDidTapRefresh(_ bar: DragHandleBar)
    func dragHandleBarDidTapPin(_ bar: DragHandleBar)
}

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

// MARK: - Drag Handle Bar

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
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: isPinned ? "Unpin window" : "Pin window")
        pinButton.image = image?.withSymbolConfiguration(symbolConfig)
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
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
        button.image = image?.withSymbolConfiguration(symbolConfig)
        button.bezelStyle = .inline
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.contentTintColor = .white
        button.target = self
        button.action = action
        button.setAccessibilityLabel(accessibilityLabel)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24),
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

extension WebViewController: WKUIDelegate {
    // Handle target="_blank" and window.open() — load in same webview
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if isAllowedDomain(url) {
                webView.load(navigationAction.request)
            } else {
                NSWorkspace.shared.open(url)
            }
        }
        return nil
    }
}
