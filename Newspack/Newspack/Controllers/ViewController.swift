import UIKit
import WordPressAuthenticator

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureAuthenticator()
        showAuthenticator()
    }

    func showAuthenticator() {
        WordPressAuthenticator.showLoginFromPresenter(self, animated: true)
    }

    func configureAuthenticator() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: "",
                                                               wpcomSecret: "",
                                                               wpcomScheme: "",
                                                               wpcomTermsOfServiceURL: "",
                                                               googleLoginClientId: "",
                                                               googleLoginServerClientId: "",
                                                               googleLoginScheme: "",
                                                               userAgent: "")

        WordPressAuthenticator.initialize(configuration: configuration)
        WordPressAuthenticator.shared.delegate = self
    }

}

extension ViewController: WordPressAuthenticatorDelegate {

    /// Indicates if the active Authenticator can be dismissed, or not.
    ///
    var dismissActionEnabled: Bool {
        return false
    }

    /// Indicates if the Support button action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return false
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        return false
    }

    /// Indicates if Support is available or not.
    ///
    var supportEnabled: Bool {
        return false
    }

    /// Returns true if there isn't a default WordPress.com account connected in the app.
    var allowWPComLogin: Bool {
        return true
    }

    /// Signals the Host App that a new WordPress.com account has just been created.
    ///
    /// - Parameters:
    ///     - username: WordPress.com Username.
    ///     - authToken: WordPress.com Bearer Token.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func createdWordPressComAccount(username: String, authToken: String) {

    }

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {

    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, onDismiss: @escaping () -> Void) {

    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, service: SocialService?) {

    }

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {

    }

    /// Indicates if the Login Epilogue should be displayed.
    ///
    /// - Parameter isJetpackLogin: Indicates if we've just logged into a WordPress.com account for Jetpack purposes!.
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        return false
    }

    /// Indicates if the Signup Epilogue should be displayed.
    ///
    func shouldPresentSignupEpilogue() -> Bool {
        return false
    }

    /// Signals the Host App that a WordPress Site (wpcom or wporg) is available with the specified credentials.
    ///
    /// - Parameters:
    ///     - credentials: WordPress Site Credentials.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func sync(credentials: WordPressCredentials, onCompletion: @escaping () -> Void) {

    }

    /// Signals the Host App that a given Analytics Event has occurred.
    ///
    func track(event: WPAnalyticsStat) {

    }

    /// Signals the Host App that a given Analytics Event (with the specified properties) has occurred.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {

    }

    /// Signals the Host App that a given Analytics Event (with an associated Error) has occurred.
    ///
    func track(event: WPAnalyticsStat, error: Error) {

    }
}
