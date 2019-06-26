import Foundation
import WordPressKit
import WordPressFlux

enum SessionState {
    case uninitialized
    case initialized
}

/// SessionManager is responsible for defining the current session for the
/// current account and site.  It serves to help decouple the API and Store layers.
///
class SessionManager: StatefulStore<SessionState> {

    /// Singleon reference
    ///
    static let shared = SessionManager()

    /// A readonly reference to the api.
    /// The API is an anonymous API until initialzed with an Account
    ///
    private(set) var api = WordPressCoreRestApi(oAuthToken: nil, userAgent: UserAgent.defaultUserAgent)

    private var accountStoreSubscription: Receipt?

    private init() {
        super.init(initialState: .uninitialized)

        let store = StoreContainer.shared.accountStore
        accountStoreSubscription = store.onChange( accountStoreChangeHandler )
    }

    /// Initialize the session with the specified account.  Typically this will
    /// be the current account from the AccountStore
    ///
    /// - Parameter account: The account for the session. All api calls will be made
    /// on behalf of the account.
    ///
    @discardableResult
    func initialize(account: Account?) -> Bool {
        guard let account = account else {
            api = WordPressCoreRestApi(oAuthToken: nil, userAgent: UserAgent.defaultUserAgent)
            state = .uninitialized
            return false
        }

        let store = StoreContainer.shared.accountStore
        let token = store.getAuthTokenForAccount(account)

        let site = (account.currentSite?.url ?? account.networkUrl)!
        api = WordPressCoreRestApi(oAuthToken: token, userAgent: UserAgent.defaultUserAgent, site: site)

        state = .initialized

        return token != nil
    }

    /// Handle changes broacast by the account store.  Primarily used to re-initialize
    /// the api in the event the current account changes.
    ///
    func accountStoreChangeHandler() {
        initialize(account: StoreContainer.shared.accountStore.currentAccount)
    }
}
