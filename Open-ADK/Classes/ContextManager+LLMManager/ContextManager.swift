import SwiftSoup

// ToDo: Fix img tags without /> at the end are not pulled properly
// ToDo: Fix new lines within links and images
class ContextManager {
    var cWhitelist: Whitelist?
    
    init() {
        setupWhitelist()
    }
    
    func setupWhitelist() {
        do {
            cWhitelist = try Whitelist.none()
                .addTags(
                    "title", "h1", "h2", "h3", "h4", "h5", "h6",
                    "a", "br", "li", "p", "img", "span"
                    // , "div"
                )
                .addAttributes("a", "href")
                .addProtocols("a",  "href", "#", "href", "ftp", "http", "https") // Allows all other href's including js
                .addAttributes("img", "src", "alt")
                .addProtocols("img", "src", "#", "href", "ftp", "http", "https")
                .preserveRelativeLinks(true)

        } catch {
            cWhitelist = Whitelist.none()
            print("Error parsing HTML with SwiftSoup: \(error)")
        }
    }
    
    func pullContext(for webView: WKWebView) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { result, error in
            if let html = result as? String {
                
                var cleanedHTML = self.parseHTML(html: html)
                cleanedHTML = self.replaceTags(for: cleanedHTML)
                print("Cleaned HTML: \n\(cleanedHTML)")
                
            } else {
                print("Failed to Extract Content")
            }
        }
    }
    
    func replaceTags(for html: String) -> String {
        var returnedHTML = removeSpanTags(from: html)
        //returnedHTML = removeWhiteSpace(from: returnedHTML)
        returnedHTML = formatImagesInHTML(from: returnedHTML)
        returnedHTML = formatLinksInHTML(from: returnedHTML)
        returnedHTML = replaceKeyTags(from: returnedHTML)
        returnedHTML = removeWhiteSpace(from: returnedHTML)
        return returnedHTML
        
        func removeSpanTags(from html: String) -> String {
            let pattern = #"<span>(.*?)<\/span>"#
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return html
            }
            
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let newHTML = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "$1")
            
            // If nothing changed, stop recursion
            if newHTML == html {
                return newHTML
            } else {
                return removeSpanTags(from: newHTML)
            }
        }
        
        func removeWhiteSpace(from html: String) -> String {
            let pattern = #"\s\s+"#
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return html
            }
            
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let newHTML = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "\n")
            
            return newHTML
        }
        
        func formatLinksInHTML(from html: String) -> String {
            var formatted = html
            
            let patterns: [(pattern: String, template: String)] = [
                (#"<a.*?href="([^"]*)".*?>([\s\S]*?)<\/a>"#, "[$2]($1)\n"),
                (#"<a>([\s\S]*?)<\/a>"#, "[$1]()\n"),
            ]
            
            for (pattern, template) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    continue
                }
                
                let range = NSRange(formatted.startIndex..<formatted.endIndex, in: formatted)
                formatted = regex.stringByReplacingMatches(
                    in: formatted,
                    options: [],
                    range: range,
                    withTemplate: template
                )
            }
            
            return formatted
        }
        
        func formatImagesInHTML(from html: String) -> String {
            var formatted = html
            
            let patterns: [(pattern: String, template: String)] = [
                (#"<img.*?src="([^"]*)" alt="([^"]*)".*?/?>"#, "![$2]($1)\n"),
                (#"<img.*?alt="([^"]*)" src="([^"]*)".*?/?>"#, "![$1]($2)\n"),
                (#"<img.*?alt="([^"]*)".*?/?>"#, "![$1]()\n")
            ]
            
            for (pattern, template) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    continue
                }
                
                let range = NSRange(formatted.startIndex..<formatted.endIndex, in: formatted)
                formatted = regex.stringByReplacingMatches(
                    in: formatted,
                    options: [],
                    range: range,
                    withTemplate: template
                )
            }
            
            return formatted
        }
        
        func replaceKeyTags(from html: String) -> String {
            let tags = [
                "<title>": "# Title: ",
                "</title>": "\n",
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
                "<small>": "",
                "</small>": "",
                
                "<time>":"",
                "</time>":"",
                
                "<code>": "`",
                "</code>": "`",
                
                "<blockquote>": "> ",
                "</blockquote>": "\n",
                "<li></li>": "",
                "<li>": "* ",
                "</li>": "\n",
                
                "<h1>": "# ", "</h1>": "\n\n",
                "<h2>": "## ", "</h2>": "\n\n",
                "<h3>": "### ", "</h3>": "\n\n",
                "<h4>": "#### ", "</h4>": "\n\n",
                "<h5>": "##### ", "</h5>": "\n\n",
                "<h6>": "###### ", "</h6>": "\n\n",
            ]
            
            var cleanedHTML = html
            for tag in tags {
                cleanedHTML = cleanedHTML.replacingOccurrences(of: tag.key, with: tag.value)
            }
            
            return cleanedHTML
        }
    }
    
    func parseHTML(html: String) -> String {
        if let whitelist = self.cWhitelist {
            do {
                
                let document = try SwiftSoup.parse(html)
                
                let nonRenderedTags = ["script","script nonce", "style", "template", "noscript"]
                for tag in nonRenderedTags {
                    let elements = try document.select(tag)
                    for element in elements.array() {
                        try element.remove()
                    }
                }

                let hiddenElements = try document.select("[hidden], [aria-hidden='true'], [aria-expanded='false']")
                for element in hiddenElements.array() {
                    try element.remove()
                }

                let elementsWithStyle = try document.select("[style]")
                for element in elementsWithStyle.array() {
                    let style = try element.attr("style").replacingOccurrences(of: " ", with: "").lowercased()
                    if style.contains("display:none") || style.contains("visibility:hidden") {
                        try element.remove()
                    }
                }
                
                let cleanedHTML = try document.outerHtml()
                
                
                let cleanHtml = try SwiftSoup.clean(cleanedHTML, whitelist)

                return cleanHtml ?? ""
            } catch {
                return ""
            }
        } else {
            return ""
        }
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
