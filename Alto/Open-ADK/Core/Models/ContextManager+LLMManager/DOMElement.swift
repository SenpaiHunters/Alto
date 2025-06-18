//
import SwiftSoup

// MARK: - DOMElement

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
            handlePropagation()
        }

        self.tree.elementLookup[id] = self
    }

    func handlePropagation() {
        if let element {
            for child in element.getChildNodes() {
                if let node = child as? Element {
                    addChild(node, propagate: true)
                }
            }
        }
    }

    func addChild(_ element: Element, propagate: Bool = false) {
        let child = Div(tree, element: element, depth: depth + 1, propagate: propagate)
        children.append(child)
        child.parent = self
    }

    func addChild(_ element: DOMElement) {
        children.append(element)
        element.parent = self
        element.depth = depth + 1
    }

    func replaceSelfWithChild(_ element: DOMElement) {
        parent?.addChild(element)
        removeSelf()
    }

    func removeSelf() {
        parent?.children.removeAll(where: { $0.id == self.id })
        tree.elementLookup.removeValue(forKey: id)
    }
}

// MARK: - Html

class Html: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil, propagate: Bool = false) { super.init(
        tree,
        tagName: "html",
        element: element
    ) }
}

// MARK: - Head

class Head: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "head", element: element) }
}

// MARK: - Body

class Body: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "body", element: element) }
}

// MARK: - Title

class Title: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "title", element: element) }
}

// MARK: - Meta

class Meta: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "meta", element: element) }
}

// MARK: - Link

class Link: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "link", element: element) }
}

// MARK: - Script

class Script: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "script", element: element) }
}

// MARK: - Style

class Style: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "style", element: element) }
}

// MARK: - Div

class Div: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil, depth: Int = 0, propagate: Bool = false) { super.init(
        tree,
        tagName: "div",
        element: element,
        depth: depth,
        propagate: propagate
    ) }
}

// MARK: - Span

class Span: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "span", element: element) }
}

// MARK: - P

class P: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "p", element: element) }
}

// MARK: - Heading

class Heading: DOMElement {
    init(_ tree: NewDOMTree, element: Element) { super.init(
        tree,
        tagName: element.tagName().lowercased(),
        element: element
    ) }
}

// MARK: - TextDiv

class TextDiv: DOMElement {
    init(_ tree: NewDOMTree, element: Element? = nil) { super.init(tree, tagName: "text", element: element) }
}
