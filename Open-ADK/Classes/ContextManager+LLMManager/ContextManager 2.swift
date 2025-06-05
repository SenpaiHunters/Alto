import SwiftSoup

/// First we need to strip out anything that is not visible
/// Then we march through each element indexing the html as a Markdown dom representation
/// Then we need to march through each element from md dom the lowest level to the highest
/// For each element we check its parent. if the parent is a div and only holds a single child we allow (img, text, or link)
/// Than we replace the parent with the child
class ContextManager {
    init() {
        
    }
    
    func pullContext(for webView: WKWebView) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { result, error in
            if let html = result as? String {
                self.pullDOM(from: html)
            } else {
                print("Failed to Extract Content")
            }
        }
    }
    
    func pullDOM(from html: String) {
        do {
            if let document = try? SwiftSoup.parse(html) {
                if let htmlElement = try? document.select("html").first()  {
                    let domTree = DOMTree()
                    try? domTree.prossesElement(htmlElement, parrent: nil, tree: domTree)

                    for element in domTree.rootElements {
                        domTree.printTree(element)
                    }
                    domTree.prossesDOM()
                    for element in domTree.rootElements {
                        domTree.printTree(element)
                    }
                    domTree.prossesDOM()
                }
            }
        }
    }
    
}
