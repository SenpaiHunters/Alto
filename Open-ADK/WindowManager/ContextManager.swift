import SwiftSoup

class ContextManager {
    let cWhitelist: Whitelist?
    init() {
        do {
            cWhitelist = try Whitelist.none()
                .addTags(
                    "title", "h1", "h2", "h3", "h4", "h5", "h6",
                    "a", "em", "strong", "small", "s", "cite", "q", "dfn", "abbr",
                    "time", "code", "var", "samp", "kbd", "sub", "sup",
                    "i", "b", "u", "mark", "span", "br", "wbr", "li", "p", "div"
                )
                .addAttributes("a", "href")
                .addProtocols("a", "href", "http", "https")
                .addAttributes(":all", "href")
                .preserveRelativeLinks(true)
        } catch {
            cWhitelist = Whitelist.none()
            print("Error parsing HTML with SwiftSoup: \(error)")
        }
    }
    
    func retrieveHTML(webView: WKWebView) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { result, error in
            print("==========================================================================")
            if let html = result as? String {
               print(self.cleanHTML(html:self.parseHTML(html: html)))
            } else {
                print("Failed to Extract Content")
            }
        }
    }
    
    func parseHTML(html: String) -> String {
        if let whitelist = self.cWhitelist {
            do {
                let cleanHtml = try SwiftSoup.clean(html, whitelist)
                return cleanHtml ?? ""
            } catch {
                return ""
            }
        } else {
            return ""
        }
    }
    
    func cleanNewlinesAndWhitespace(in text: String) -> String {
        let pattern = "\\s*([\\r\\n]+)\\s*"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        let collapsed = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "\n")
        
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    
    func cleanHTML(html: String) -> String {
        let responseMessages = [
            "<div>": "",
            "</div>": "",
            "<span>": "",
            "</span>": "",
            
            "<li>": "* ",
            "</li>": "\n",
            
            "<title>": "Title: ",
            "</title>": "\n",
            
            "<h1>": "## ",
            "</h1>": "\n",
            "<h2>": "### ",
            "</h2>": "\n",
            "<h3>": "#### ",
            "</h3>": "\n",
            "<h4>": "##### ",
            "</h4>": "\n",
            "<h5>": "###### ",
            "</h5>": "\n",
            "<h6>": "###### ",
            "</h6>": "\n",

            "<br>": "\n",
            "<br/>": "\n",
            "<br />": "\n",

            "<p>": "",
            "</p>": "\n\n",

            "<b>": "**",
            "</b>": "**",
            "<strong>": "**",
            "</strong>": "**",
            "<i>": "*",
            "</i>": "*",
            "<em>": "*",
            "</em>": "*",
            "<u>": "_",
            "</u>": "_",

            "<code>": "`",
            "</code>": "`",

            "<blockquote>": "> ",
            "</blockquote>": "\n",
            "<a>": "",
            "</a>": "",
        ]

        
        var cleanedHTML = html
        cleanedHTML = formatLinksInHTML(cleanedHTML)
        for tag in responseMessages {
            cleanedHTML = cleanedHTML.replacingOccurrences(of: tag.key, with: tag.value)
        }
        cleanedHTML = self.cleanNewlinesAndWhitespace(in: cleanedHTML)
        return cleanedHTML
    }
    
    func formatLinksInHTML(_ html: String) -> String {
        let pattern = #"<a\s+href="([^"]+)">(.*?)</a>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return html
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        let formatted = regex.stringByReplacingMatches(
            in: html,
            options: [],
            range: range,
            withTemplate: "[$2]($1)"
        )
        
        return formatted
    }
}



/*
 curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=YOUR_API_KEY" \
   -H 'Content-Type: application/json' \
   -X POST \
   -d '{
     "contents": [
       {
         "parts": [
           {
             "text": "Explain how AI works in a few words"
           }
         ]
       }
     ]
   }'
 */
