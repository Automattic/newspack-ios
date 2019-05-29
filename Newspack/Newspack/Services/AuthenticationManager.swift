import Foundation
import WordPressAuthenticator
import WordPressFlux

class AuthenticationManager {

    typealias CompletionBlock = () -> Void

    /// The receipt for a subscription to the account store.
    ///
    var accountStoreSubscription: Receipt?

    /// Used to hold the competion callback when syncing.
    ///
    var syncCompletionBlock: CompletionBlock?


    init() {
        let store = StoreContainer.shared.accountStore
        accountStoreSubscription = store.accountChangeDispatcher.subscribe(storeChangeHandler(_:))
    }

    /// Initialize the authentication manager.
    /// Only necessary if showing the auth flow. Optional otherwise.
    ///
    func initialize() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: "",
                                                                googleLoginClientId: "",
                                                                googleLoginServerClientId: "",
                                                                googleLoginScheme: "",
                                                                userAgent: UserAgent.defaultUserAgent)
        WordPressAuthenticator.initialize(configuration: configuration)
        WordPressAuthenticator.shared.delegate = self

    }

    /// Handles account store change actions.
    ///
    func storeChangeHandler(_ accountChange: AccountChange) {
        switch accountChange {
        case .accountCreated(account: _):
            syncCompletionBlock?()
            syncCompletionBlock = nil
        default:
            break
        }
    }

    /// Returns true if authentication is required.
    ///
    func authenticationRequred() -> Bool {
        let store = StoreContainer.shared.accountStore
        return store.numberOfAccounts() == 0
    }

    /// Shows the login flow.  The flow is presented from the specified controller.
    ///
    /// - Parameteres:
    ///     - controller: The UI view controller to present the auth flow.
    ///
    func showAuthenticator(controller: UIViewController) {
        guard let _ = WordPressAuthenticator.shared.delegate as? AuthenticationManager else {
            // TODO: Log that we're not initialized.
            return
        }
        WordPressAuthenticator.showLoginForSelfHostedSite(controller)
    }

    /// Processes the supplied credentials.
    ///
    /// - Parameters:
    ///     - authToken: The REST API bearer token to be used for the acccount.
    ///     - site: The site (or multi-site) for the auth token.
    ///
    func processCredentials(authToken: String, site: String, onCompletion: @escaping () -> Void) {
        syncCompletionBlock = onCompletion
        let action = AccountAction.create(authToken: authToken, site: site)
        ActionDispatcher.global.dispatch(action)
    }
}


extension AuthenticationManager: WordPressAuthenticatorDelegate {
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (Error?, Bool) -> Void) {
        onCompletion(nil, true)
    }


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
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) {

    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {

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
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        if let creds = credentials.wpcom {
            processCredentials(authToken: creds.authToken, site: creds.siteURL, onCompletion: onCompletion)
        } else if let _ = credentials.wporg {
            // TODO: handle this
        }
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
