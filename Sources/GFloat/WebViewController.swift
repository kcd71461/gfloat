import AppKit
import WebKit

class WebViewController: NSViewController {
    private var webView: WKWebView!

    override func loadView() {
        let container = NSView()

        // Drag handle bar
        let handleBar = DragHandleBar()
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

// MARK: - Drag Handle Bar

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
