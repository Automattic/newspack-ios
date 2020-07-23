import UIKit
import WebKit
import Gridicons

/// A simple web view controller, based on WebKitViewController from WPiOS.
///
class WebViewController: UIViewController {

    @IBOutlet var webView: WKWebView!
    @IBOutlet var reloadButton: UIBarButtonItem!
    @IBOutlet var safariButton: UIBarButtonItem!
    @IBOutlet var closeButton: UIBarButtonItem!
    @IBOutlet var prevButton: UIBarButtonItem!
    @IBOutlet var nextButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!

    private(set) var url: URL?

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        startObservingWebView()
        configureToolbar()

        webView.customUserAgent = UserAgent.defaultUserAgent

        if let url = url {
            load(url: url)
        }
    }

    private func configureToolbar() {
        reloadButton.image = UIImage.gridicon(.refresh)
        safariButton.image = UIImage.gridicon(.globe)
        closeButton.image = UIImage.gridicon(.cross)
        prevButton.image = UIImage.gridicon(.chevronLeft)
        nextButton.image = UIImage.gridicon(.chevronRight)
        shareButton.image = UIImage.gridicon(.shareiOS)

        navigationController?.setToolbarHidden(false, animated: false)
    }

    private func startObservingWebView() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
         guard let object = object as? WKWebView,
             object == webView,
             let keyPath = keyPath else {
                 return
         }

         switch keyPath {
         case #keyPath(WKWebView.title):
            navigationItem.title = webView.title
         case #keyPath(WKWebView.url):
             // If the site has no title, use the url.
             if webView.title?.nonEmptyString() == nil {
                 navigationItem.title = webView.url?.host
             }
             navigationItem.prompt = webView.url?.host
             let haveUrl = webView.url != nil
             shareButton.isEnabled = haveUrl
             safariButton.isEnabled = haveUrl
             navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = haveUrl }
         case #keyPath(WKWebView.isLoading):
             prevButton.isEnabled = webView.canGoBack
             nextButton.isEnabled = webView.canGoForward
         default:
             assertionFailure("Observed change to web view that we are not handling")
         }

         // Accessibility values which emulate those found in Safari
         navigationItem.accessibilityLabel = NSLocalizedString("Title", comment: "Accessibility label for web page preview title")
         navigationItem.titleView?.accessibilityValue = navigationItem.title
         navigationItem.titleView?.accessibilityTraits = .updatesFrequently
     }
}

// MARK: - Public Methods

extension WebViewController {

    /// Load the specified URL in the controller's webview.
    ///
    /// - Parameter url: The URL to load.
    ///
    func load(url: URL) {
        self.url = url
        guard isViewLoaded else {
            return
        }
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url)
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }

}

// MARK: - Actions

extension WebViewController {

    @IBAction func handleCloseButton(sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func handleRefreshButton(sender: UIBarButtonItem) {
        webView.reload()
    }

    @IBAction func handleSafariButton(sender: UIBarButtonItem) {
        guard let url = webView.url else {
            return
        }
        UIApplication.shared.open(url)
    }

    @IBAction func handleShareButton(sender: UIBarButtonItem) {
        guard let url = webView.url else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.modalPresentationStyle = .popover
        activityViewController.popoverPresentationController?.barButtonItem = shareButton
        present(activityViewController, animated: true)
    }

    @IBAction func handlePrevButton(sender: UIBarButtonItem) {
        webView.goBack()
    }

    @IBAction func handleNextButton(sender: UIBarButtonItem) {
        webView.goForward()
    }
}
