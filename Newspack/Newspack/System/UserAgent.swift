import Foundation
import WebKit

/// Wrangles the user agent used by the app.
///
/// The user agent is composed of a userAgent retrieved from a WKWebViews with the app's
/// identifier and version appeneded.
///
/// Due to the way WKWebView's execute JavaScript asychronously the user agent should
/// be configured well in advance of its first intended usage.  Do this by
/// calling `UserAgent.configure()`
///
class UserAgent {

    private var webView: WKWebView?

    /// Returns the default user agent.
    ///
    static var defaultUserAgent: String {
        return webUserAgent + " " + Constants.appIdentifier + "/" + bundleShortVersion
    }

    /// Returns the user agent used by WKWebViews
    ///
    static var webUserAgent: String {
        return UserDefaults.shared.string(forKey: Constants.webUserAgentKey) ?? String()
    }

    /// Returns the version number of the app.
    ///
    static var bundleShortVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: Constants.shortVersionKey) as? String
        return version ?? String()
    }

    /// Convenience method for configuring the stored user agent.
    ///
    class func configure() {
        let ua = UserAgent()
        ua.configureIfNecessary()
    }

    /// Checks for the existance of a stored user agent.
    ///
    private func configureIfNecessary() {
        // If a stored user agent exists there's nothing to do.
        guard UserDefaults.shared.string(forKey: Constants.webUserAgentKey) == nil else {
            return
        }
        webView = WKWebView()
        webView?.evaluateJavaScript(Constants.userAgentJavascript) { (result, error) in
            if let result = result as? String {
                self.storeUserAgent(agent: result)
            }
            self.webView = nil
        }
    }

    /// Stores the specified string in UserDefaults
    ///
    /// - Parameter agent: The string for the user agent.
    ///
    private func storeUserAgent(agent: String) {
        UserDefaults.shared.set(agent, forKey: Constants.webUserAgentKey)
    }
}

private extension UserAgent {

    struct Constants {

        /// Defaults key for stored web user agent
        ///
        static let webUserAgentKey = "webUserAgentKey"

        /// UserAgent Prefix
        ///
        static let appIdentifier = "newspack-ios"

        /// Load User Agent JS Script
        ///
        static let userAgentJavascript = "navigator.userAgent"

        /// Short Version Key
        ///
        static let shortVersionKey = "CFBundleShortVersionString"
    }
}

