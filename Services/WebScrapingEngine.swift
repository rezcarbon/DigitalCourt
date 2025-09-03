import Foundation
import WebKit
import Combine

/// Advanced web scraping engine for CIM autonomous operations
@MainActor
class WebScrapingEngine: NSObject, ObservableObject {
    
    private var webView: WKWebView
    private var currentScrapeCompletion: ((String) -> Void)?
    
    override init() {
        let config = WKWebViewConfiguration()
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            config.preferences.javaScriptEnabled = true
        }
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
    }
    
    func scrape(url: String, selector: String?) async -> String {
        return await withCheckedContinuation { continuation in
            currentScrapeCompletion = { result in
                continuation.resume(returning: result)
            }
            
            guard let webURL = URL(string: url) else {
                continuation.resume(returning: "Invalid URL: \(url)")
                return
            }
            
            let request = URLRequest(url: webURL)
            webView.load(request)
        }
    }
    
    private func extractContent(selector: String?) {
        let script: String
        if let selector = selector {
            script = """
                try {
                    const elements = document.querySelectorAll('\(selector)');
                    const content = Array.from(elements).map(el => el.textContent || el.innerText).join('\\n');
                    content || 'No content found for selector: \(selector)';
                } catch (error) {
                    'Error extracting content: ' + error.message;
                }
            """
        } else {
            script = """
                try {
                    document.body.textContent || document.body.innerText || 'No content found';
                } catch (error) {
                    'Error extracting content: ' + error.message;
                }
            """
        }
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            let content = (result as? String) ?? "Error: \(error?.localizedDescription ?? "Unknown error")"
            self?.currentScrapeCompletion?(content)
            self?.currentScrapeCompletion = nil
        }
    }
}

extension WebScrapingEngine: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait a moment for dynamic content to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.extractContent(selector: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        currentScrapeCompletion?("Navigation failed: \(error.localizedDescription)")
        currentScrapeCompletion = nil
    }
}