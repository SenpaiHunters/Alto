//
import SwiftSoup

class NewDOMTree {
    var document: Document?
    var rootElement: DOMElement?
    var elementLookup: [UUID:DOMElement] = [:]
    
    
    init(for html: String, sanatize: Bool = true) {
        do {
            self.document = try SwiftSoup.parse(html)
        } catch {
            print("failed to convert to document")
        }
        
        if sanatize {
            self.stripHiddenContent()
        }
        
        self.constructDOM()
        print("===============================================================")
        if let rootElement = self.rootElement {
            self.printTree(rootElement)
        }
        
        print("===============================================================")
        print("done!")
    }
    
    func stripHiddenContent() {
        guard let document = self.document else {
            return
        }
        do {
            let hiddenTags = ["script","script nonce", "style", "template", "noscript"]
            for tag in hiddenTags {
                let elements = try document.select(tag)
                for element in elements {
                    try element.remove()
                }
            }
            
            let hiddenElements = try document.select("[hidden], [aria-hidden='true'], [aria-expanded='false']")
            for element in hiddenElements {
                try element.remove()
            }
            
            let hiddenStyleElements = try document.select("[style]")
            for element in hiddenStyleElements {
                let style = try element.attr("style")
                let pattern = #"display\s*:\s*none"#
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(style.startIndex..<style.endIndex, in: style)
                
                if regex.firstMatch(in: style, options: [], range: range) != nil {
                    try element.remove()
                }
            }
        } catch {
            print("failed to strip hidden content")
        }
    }
    
    func constructDOM() {
        guard let document = self.document else {
            return
        }
        
        do {
            if let body = try document.select("body").first() {
                let bodyDOM = Div(self, element: body)
                self.rootElement = bodyDOM
                for child in body.getChildNodes() {
                    if let node = child as? Element {
                        bodyDOM.addChild(node, propagate: true)
                        print(try node.text(), "\n")
                    }
                }
            }
        } catch {
            print()
        }
    }
    
    func printTree(_ element: DOMElement, indent: String = "") {
        if element.children.count != 0 {
            print("\(indent)- \(type(of: element)) depth: \(element.depth)")
        } else {
            print("\(indent)- content: \(String(describing: try? element.element?.text())) depth: \(element.depth)")
        }
        for child in element.children {
            printTree(child, indent: indent + "  ")
        }
    }
    
    func printMD(_ element: DOMElement, indent: String = "") {
        if element.children.count != 0 {
            print("\n")
        } else {
            let text = (try? element.element?.text()) ?? ""
            
            print("\(text)")
        }
        for child in element.children {
            printMD(child, indent: indent + "  ")
        }
    }
    
    
    func collapseDOMIterative() {
        // ToDo: add code here lol
    }
}



