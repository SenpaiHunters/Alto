//
import SwiftSoup


class DOMTree {
    var elementMap: [UUID: DOMElement] = [:]
    var rootElements: [DOMElement] = []
    
    init() {
        
    }
    
    func printTree(_ element: DOMElement, indent: String = "") {
        print("\(indent)- \(type(of: element)) Depth: \(element.depth)")
        for child in element.children {
            printTree(child, indent: indent + "  ")
        }
    }

    func prossesElement(_ element: Element, parrent: DOMElement?, customElement: DOMElement? = nil, tree: DOMTree = DOMTree()) throws {
        let tagName = element.tagName().lowercased()
        
        let MDElement: DOMElement = customElement ?? {
            switch tagName {
            case "html": return Html(tree)
            case "head": return Head(tree)
            case "body": return Body(tree)
            case "title": return Title(tree)
            case "meta": return Meta(tree)
            case "link": return Link(tree)
            case "script": return Script(tree)
            case "style": return Style(tree)
            case "div": return Div(tree)
            case "span": return Span(tree)
            case "p": return P(tree)
            case "h1", "h2", "h3", "h4", "h5", "h6": return Heading(tree)
            default: return Div(tree)
            }
        }()
        
        if tagName == "html" {
            self.rootElements.append(MDElement)
        }
        
        if let parrent {
            parrent.addChild(MDElement)
        }
        
        for child in element.children() {
            try prossesElement(child, parrent: MDElement, tree: tree)
        }
    }
    
    func prossesDOM() {
        if let maxValue = elementMap.values.map({ $0.depth }).max() {
            
            let maxEntries = elementMap.filter { $0.value.depth == maxValue }
            print("Max Value: \(maxValue)")
            print("Max Entries: \(maxEntries)")
            
            for element in maxEntries {
                if element.value.tagName == "div" {
                    self.elementMap.removeValue(forKey: element.key)
                    element.value.parent?.children.removeAll(where: { $0.id == element.key})
                }
                if element.value.parent?.children.count == 0 {
                    
                } else {
                    print("multiple childs: \(element.value.parent?.tagName)")
                }
            }
    
        }
    }
}

class DOMElement {
    var id = UUID()
    var tree: DOMTree
    weak var parent: DOMElement?
    var children: [DOMElement] = []
    var content: String?
    var depth: Int
    let tagName: String
    
    init(_ tree: DOMTree, tagName: String, depth: Int = 0) {
        self.tree = tree
        self.tagName = tagName
        self.depth = depth
        self.tree.elementMap[self.id] = self
    }
    
    func addChild(_ child: DOMElement) {
        self.children.append(child)
        child.parent = self
        let childDepth = self.depth + 1
        child.depth = childDepth
        self.tree.elementMap[child.id] = child
    }
}
class Html: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "html") }
}
class Head: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "head") }
}
class Body: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "body") }
}
class Title: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "title") }
}
class Meta: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "meta") }
}
class Link: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "link") }
}
class Script: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "script") }
}
class Style: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "style") }
}

class Div: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "div") }
}
class Span: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "span") }
}
class P: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "p") }
}
class Heading: DOMElement {
    init(_ tree: DOMTree) { super.init(tree, tagName: "h") } // or "h1" etc, depending on usage
}
