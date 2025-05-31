

class ContextManager {
    func parseContext(webView: WKWebView) {
        let js = "document.body.innerText"
        webView.evaluateJavaScript(js) { result, error in
            if let text = result as? String {
                print(text)
            } else {
                print("Failed to Extract Content")
            }
        }
    }
}
