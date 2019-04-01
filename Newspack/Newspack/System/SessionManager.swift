import Foundation
import WordPressKit

/// SessionManager is responsible for defining the current session for the
/// current account.  It serves to decouple the API and Store layers.
///
class SessionManager {

    /// Singleon reference
    ///
    static let shared = SessionManager()

    /// A readonly reference to the api.
    /// The API is an anonymous API until initialzed with an Account
    ///
    private(set) var api = WordPressComRestApi(oAuthToken: nil, userAgent: UserAgent.defaultUserAgent)

    private init() {}

    /// Initialize the session with the specified account.  Typically this will
    /// be the current account from the AccountStore
    ///
    /// - Parameter account: The account for the session. All api calls will be made
    /// on behalf of the account.
    ///
    @discardableResult
    func initialize(account: Account) -> Bool {
        let store = StoreContainer.shared.accountStore
        guard let token = store.getAuthTokenForAccount(account) else {
            return false
        }

        api = WordPressComRestApi(oAuthToken: token, userAgent: UserAgent.defaultUserAgent)
        return true
    }

}
