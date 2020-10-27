import Foundation
import WordPressAuthenticator
import WordPressFlux
import Gridicons
import NewspackFramework

struct AuthenticationConstants {
    /// Login with site URL instructions.
    ///
    static let siteInstructions = NSLocalizedString(
        "Enter the address of the Newspack site you'd like to connect.",
        comment: "Sign in instructions for logging in with a URL."
    )

    static let usernamePasswordInstructions = NSLocalizedString(
        "Enter your WordPress.com username and password to connect to your Newspack site.",
        comment: "Instructions for logging into Newspack with WordPress.com credentials.")
}

class AuthenticationManager {

    /// Used to hold the competion callback when syncing.
    ///
    var syncCompletionBlock: (() -> Void)?

    /// Configure the WordPressAuthenticator
    /// The authenticator is a singleton instance and should only be initialized once.
    /// Otherwise it yields a fatal error.
    ///
    static private var initialized = false
    static func configure() {
        guard !initialized else {
            return
        }

        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: "",
                                                                wpcomBaseURL: "https://wordpress.com",
                                                                wpcomAPIBaseURL: "https://public-api.wordpress.com",
                                                                googleLoginClientId: "",
                                                                googleLoginServerClientId: "",
                                                                googleLoginScheme: "",
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                showLoginOptions: false,
                                                                enableSignInWithApple: false,
                                                                enableSignupWithGoogle: false,
                                                                enableUnifiedAuth: false,
                                                                enableUnifiedCarousel: false)

        let style = WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .primaryButtonBackground,
                                                primaryNormalBorderColor: nil,
                                                primaryHighlightBackgroundColor: .primaryButtonDownBackground,
                                                primaryHighlightBorderColor: nil,
                                                secondaryNormalBackgroundColor: .secondaryButtonBackground,
                                                secondaryNormalBorderColor: .secondaryButtonBorder,
                                                secondaryHighlightBackgroundColor: .secondaryButtonDownBackground,
                                                secondaryHighlightBorderColor: .secondaryButtonDownBorder,
                                                disabledBackgroundColor: .textInverted,
                                                disabledBorderColor: .neutral(.shade10),
                                                primaryTitleColor: .white,
                                                secondaryTitleColor: .text,
                                                disabledTitleColor: .neutral(.shade20),
                                                textButtonColor: .primary,
                                                textButtonHighlightColor: .primaryDark,
                                                instructionColor: .text,
                                                subheadlineColor: .textSubtle,
                                                placeholderColor: .neutral(.shade40),
                                                viewControllerBackgroundColor: .listBackground,
                                                textFieldBackgroundColor: .listForeground,
                                                buttonViewBackgroundColor: .primaryButtonBackground,
                                                navBarImage: .gridicon(.mySites),
                                                navBarBadgeColor: .gray,
                                                navBarBackgroundColor: .appBar,
                                                prologueBackgroundColor: .primary,
                                                prologueTitleColor: .textInverted)

        let displayStrings = WordPressAuthenticatorDisplayStrings(siteLoginInstructions: AuthenticationConstants.siteInstructions,
                                                                  usernamePasswordInstructions: AuthenticationConstants.usernamePasswordInstructions)

        WordPressAuthenticator.initialize(configuration: configuration,
                                          style: style,
                                          unifiedStyle: nil,
                                          displayImages: WordPressAuthenticatorDisplayImages.defaultImages,
                                          displayStrings: displayStrings)
        initialized = true
    }

    init() {
        AuthenticationManager.configure()
        WordPressAuthenticator.shared.delegate = self
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
            LogWarn(message: "showAuthenticator: Tried to show authenticator flow before authenticator was initialized.")
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
    func processCredentials(authToken: String, url: String, onCompletion: @escaping () -> Void) {
        syncCompletionBlock = onCompletion

        let accountHelper = AccountSetupHelper(token: authToken, network: url)
        accountHelper.configure { (error) in
            if let error = error {
                // This could happen if there is a network error whle configuring the account.
                // In this case we probably need to restart the flow from the beginning.
                LogError(message: error.localizedDescription)
                self.promptAndNotifyUnableToLogIn()
                return
            }
            self.performSyncCompletion()
        }
    }

    /// Fires the sync completion block if it exists
    ///
    private func performSyncCompletion() {
        syncCompletionBlock?()
        syncCompletionBlock = nil
    }

}


extension AuthenticationManager: WordPressAuthenticatorDelegate {

    func promptAndNotifyUnableToLogIn() {
        NotificationCenter.default.post(name: .authNeedsRestart, object: nil)
    }

    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
        // No op
    }

    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (Error?, Bool) -> Void) {
        if siteInfo?.isWPCom == false && siteInfo?.hasJetpack == false {
            let error = AuthErrors.invalidCredentialsError()
            onCompletion(error, false)
            return
        }
        // Pass false, regardless of whether this is a self-hosted site or not.
        // This is so the authenticator will always attempt wpcom auth.
        // The instructions shown to the user will be to use wpcom credentials.
        onCompletion(nil, false)
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
        guard let creds = credentials.wpcom else {
            // A self-hosted (or unsupported) login.
            // This shouldn't happen but if it does log the error and restart the flow.
            LogError(message: "Attempted log in with unsupported credentials.")
            self.promptAndNotifyUnableToLogIn()
            return
        }
        processCredentials(authToken: creds.authToken, url: creds.siteURL, onCompletion: onCompletion)
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

struct AuthErrors: Error {
    static let errorDomain = "com.automattic.newspack.auth"

    enum Codes: Int {
        case invalidCredentials
    }

    static func invalidCredentialsError() -> Error {
        let domain = errorDomain

        let message = NSLocalizedString(
            "Unable to log in with the credentials provided. Please use the WordPress.com credentials used to connect your Newspack site to Jetpack.",
            comment: "An error message.")

        let userInfo = [NSLocalizedDescriptionKey: message]

        return NSError(domain: domain, code: AuthErrors.Codes.invalidCredentials.rawValue, userInfo: userInfo)
    }

}

extension Notification.Name {
    static let authNeedsRestart = Notification.Name("AuthenticationNeedsRestart")
}
