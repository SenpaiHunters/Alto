//



import Observation
import SwiftUI
import WebKit

@Observable
class WebViewManager: NSObject, WKNavigationDelegate, WKUIDelegate, Identifiable {
    var id = UUID()
    var webView: WKWebView
    var favicon: NSImage? = nil
    var isLoading: Bool? = nil
    var title: String? = nil
    var url: URL?
    var mannager: Browser
    
    init(manager: Browser, url: String) {
        self.webView = WKWebView()
        self.mannager = manager
        let config = WKWebViewConfiguration()
            config.websiteDataStore = .default()

        self.webView = WKWebView(frame: .zero, configuration: config)
        
        super.init()
        
        self.load(string: url)
        self.url = URL(string: url)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        self.isLoading = nil
        self.title = nil
        
        self.webView.allowsMagnification = true
        //self.webView.allowsBackForwardNavigationGestures = true
        self.webView.configuration.preferences.isElementFullscreenEnabled = true
        self.webView.allowsLinkPreview = true
        self.webView.isInspectable = true
        
    }

    func load(string: String) {
        if let url = URL(string: string) {
            webView.load(URLRequest(url: url))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("FINISHED LOADING")
        self.isLoading = true
        print("Title: \(webView.title ?? "nil")")
        self.title = webView.title
        getFavicon()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("STARTED LOADING")
        self.isLoading = false
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            print("🆕 New tab or window requested: \(navigationAction.request.url?.absoluteString ?? "unknown URL")")
            if let url = navigationAction.request.url?.absoluteString {
                self.mannager.newTab()
            }
        }
        return nil
    }
    
    func getFavicon() {
        webView.evaluateJavaScript(
            "document.querySelector(\"link[rel~='icon']\")?.href"
        ) { result, error in
            if let value = result as? String {
                print("VALUE: ", value)
                print("Favicon URL from JS:", value)
                self.downloadFavicon(from: value)
            } else {
                if let host = self.webView.url?.host {
                    let fallbackFavicon = "https://\(host)/favicon.ico"
                    print("Using fallback favicon:", fallbackFavicon)
                    self.downloadFavicon(from: fallbackFavicon)
                }
            }

        }
    }

    func downloadFavicon(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.favicon = image
                }
            }
        }.resume()
    }

}

struct NSWebView: NSViewRepresentable {
    var mannager: WebViewManager

    func makeNSView(context: Context) -> WKWebView {
        return mannager.webView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {

    }
}

struct WebView: View {
    @State var webViewMannager: WebViewManager {
        didSet {
            print("webViewMannager:", webViewMannager)
        }
    }
    
    var body: some View {
        NSWebView(mannager: webViewMannager)
    }
}
