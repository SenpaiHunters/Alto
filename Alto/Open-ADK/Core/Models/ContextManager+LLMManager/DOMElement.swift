//
import SwiftSoup


class DOMElement {
    var id = UUID()
    var tree: NewDOMTree
    weak var parent: DOMElement?
    var children: [DOMElement] = []
    var element: Element?
    var depth: Int
    let tagName: String
    
    init(_ tree: NewDOMTree, tagName: String, element: Element? = nil, depth: Int = 0, propagate: Bool = false) {
        self.tree = tree
        self.tagName = tagName
        self.element = element
        self.depth = depth
        
        if propagate == true {
            self.handlePropagation()
        }
        
        self.tree.elementLookup[id] = self
    }
    
    func handlePropagation() {
        if let element = self.element {
            for child in element.getChildNodes() {
                if let node = child as? Element {
                    self.addChild(node, propagate: true)
                }
            }
        }
    }
    
    func addChild(_ element: Element, propagate: Bool = false) {
        let child = Div(tree, element: element, depth: self.depth + 1, propagate: propagate)
        self.children.append(child)
        child.parent = self
    }
    
    func addChild(_ element: DOMElement) {
        self.children.append(element)
        element.parent = self
        element.depth = self.depth + 1
    }
    
    func replaceSelfWithChild(_ element: DOMElement) {
        self.parent?.addChild(element)
        removeSelf()
    }
    
    func removeSelf() {
        self.parent?.children.removeAll(where: { $0.id == self.id})
        self.tree.elementLookup.removeValue(forKey: self.id)
    }
}

class Html: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil, propagate: Bool = false) { super.init(tree, tagName: "html", element: element) }
}
class Head: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "head", element: element) }
}
class Body: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "body", element: element) }
}
class Title: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "title", element: element) }
}
class Meta: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "meta", element: element) }
}
class Link: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "link", element: element) }
}
class Script: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "script", element: element) }
}
class Style: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "style", element: element) }
}

class Div: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil, depth: Int = 0, propagate: Bool = false) { super.init(tree, tagName: "div", element: element, depth: depth, propagate: propagate) }
}
class Span: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "span", element: element) }
}
class P: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "p", element: element) }
}
class Heading: DOMElement {
    init(_ tree: NewDOMTree, element: Element) { super.init(tree, tagName: element.tagName().lowercased(), element: element) }
}

class TextDiv: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "text", element: element) }
}

