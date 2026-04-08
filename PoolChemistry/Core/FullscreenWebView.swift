import SwiftUI
import WebKit

// MARK: - WebView Coordinator
class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: FullscreenWebViewRepresentable
    var lastRedirectURL: URL?

    init(_ parent: FullscreenWebViewRepresentable) {
        self.parent = parent
    }

    // MARK: - Navigation Delegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString
        lastRedirectURL = url

        if urlString.hasPrefix("paytmmp://") || urlString.hasPrefix("phonepe://") || urlString.hasPrefix("bankid://") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") && !urlString.hasPrefix("about:") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        if urlString.hasPrefix("tel:") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        if urlString.hasPrefix("mailto:") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.isLoading = false
        parent.onPageFinished?(webView.url)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        parent.isLoading = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent.isLoading = false
        handleError(error, webView: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        parent.isLoading = false
        handleError(error, webView: webView)
    }

    private func handleError(_ error: Error, webView: WKWebView) {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorHTTPTooManyRedirects {
            if let url = lastRedirectURL {
                print("[WebView] Too many redirects - reloading: \(url)")
                let request = URLRequest(url: url)
                webView.load(request)
                return
            }
        }

        if nsError.code == NSURLErrorCancelled { return }

        print("[WebView] Error: \(error.localizedDescription)")
        parent.onError?(error)
    }

    // MARK: - UI Delegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        } else {
            completionHandler()
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        } else {
            completionHandler(false)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in textField.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        } else {
            completionHandler(nil)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - WebView Representable
struct FullscreenWebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    var webView: WKWebView

    var onPageFinished: ((URL?) -> Void)?
    var onError: ((Error) -> Void)?

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        DispatchQueue.main.async {
            self.canGoBack = webView.canGoBack
        }
    }
}

// MARK: - WebView Manager
class WebViewManager: ObservableObject {
    let webView: WKWebView
    @Published var canGoBack: Bool = false
    @Published var isLoading: Bool = true

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = preferences

        config.websiteDataStore = .default()

        let contentController = WKUserContentController()
        let disableZoomScript = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        if (head) { head.appendChild(meta); }
        """
        let userScript = WKUserScript(source: disableZoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bouncesZoom = false

        webView.customUserAgent = WebViewManager.getCustomUserAgent()
    }

    private static func getCustomUserAgent() -> String {
        let osVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let model = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        return "Mozilla/5.0 (\(model); CPU iPhone OS \(osVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(UIDevice.current.systemVersion) Mobile/15E148 Safari/604.1"
    }

    func goBack() {
        if webView.canGoBack { webView.goBack() }
    }

    func reload() {
        webView.reload()
    }

    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - Fullscreen WebView
struct FullscreenWebView: View {
    let urlString: String
    @StateObject private var webViewManager = WebViewManager()
    @State private var isLoading = true
    @State private var canGoBack = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let url = URL(string: urlString) {
                    FullscreenWebViewRepresentable(
                        url: url,
                        isLoading: $isLoading,
                        canGoBack: $canGoBack,
                        webView: webViewManager.webView,
                        onPageFinished: { _ in },
                        onError: { error in print("[WebView] Error: \(error)") }
                    )
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in }
        .onReceive(PushNotificationService.shared.$pendingNotificationURL) { url in
            if let urlString = url, let url = URL(string: urlString) {
                webViewManager.loadURL(url)
                PushNotificationService.shared.clearPendingURL()
            }
        }
    }
}
