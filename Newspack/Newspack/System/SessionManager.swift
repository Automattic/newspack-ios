import Foundation
import WordPressKit
import WordPressFlux

enum SessionState {
    case pending
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

    var folderManager: FolderManager

    /// Used with UserDefaults to store the current site's uuid for later recovery.
    ///
    private var currentSiteIDKey = AppConstants.currentSiteIDKey

    /// Read only.  The ActionDispatcher for the current session.
    ///
    private (set) var sessionDispatcher = ActionDispatcher()

    /// Read only. The site for the current session.
    /// Holds the model vs its UUID to reduce the number of core data lookups.
    ///
    private(set) var currentSite: Site? {
        didSet {
            let defaults = UserDefaults.shared
            guard let uuid = currentSite?.uuid else {
                defaults.removeObject(forKey: currentSiteIDKey)
                return
            }
            defaults.set(uuid.uuidString, forKey: currentSiteIDKey)
        }
    }

    /// Read only. The API instance for the current sesion.
    /// The API is an anonymous API until the sesion is initialized.
    ///
    private(set) var api = WordPressCoreRestApi(oAuthToken: nil, userAgent: UserAgent.defaultUserAgent)

    private init() {
        let rootFolder = Environment.isTesting() ? FolderManager.createTemporaryDirectory() : nil
        folderManager = FolderManager(rootFolder: rootFolder)

        super.init(initialState: .pending)
    }

    override func onDispatch(_ action: Action) {
        guard let action = action as? AccountAction else {
            return
        }
        switch action {
        case .accountRemoved:
            handleAccountRemoved()
        default:
            break
        }
    }

    /// Initialize the session with the specified site. Typically this will be
    /// the current site when restoring the session.
    ///
    /// - Parameter site: The site for the session. The api will be configured for this site.
    /// - Returns: True if initialized, false if not.
    ///
    @discardableResult
    func initialize(site: Site?) -> Bool {
        guard
            let site = site,
            let token = AccountStore().getAuthTokenForAccount(site.account)
        else {
            sessionDispatcher = ActionDispatcher()
            api = WordPressCoreRestApi(oAuthToken: nil, userAgent: UserAgent.defaultUserAgent)
            currentSite = nil

            StoreContainer.shared.resetStores(dispatcher: sessionDispatcher, site: nil)
            state = .uninitialized
            return false
        }

        sessionDispatcher = ActionDispatcher()
        api = WordPressCoreRestApi(oAuthToken: token, userAgent: UserAgent.defaultUserAgent, site: site.url)
        currentSite = site

        StoreContainer.shared.resetStores(dispatcher: sessionDispatcher, site: site)
        state = .initialized

        return true
    }

    /// Attempt to restore the previous session.
    ///
    /// - Returns: True if the session was restored. False if not.
    ///
    @discardableResult
    func restoreSession() -> Bool {
        guard state != .initialized else {
            return false
        }
        return initialize(site: retrieveSite())
    }

    /// Attempts to retrieve the site matching the uuid string saved in user defaults.
    ///
    /// - Returns: A site model if a matching site is found. Nil otherwise.
    ///
    private func retrieveSite() -> Site? {
        guard
            let uuidString = UserDefaults.shared.string(forKey: currentSiteIDKey),
            let uuid = UUID(uuidString: uuidString)
            else {
                return nil
        }
        guard let site = SiteStore().getSiteByUUID(uuid) else {
            currentSite = nil
            return nil
        }
        return site
    }


    func handleAccountRemoved() {
        if currentSite?.isDeleted == true || currentSite?.account == nil {
            folderManager.resetCurrentFolder()
            state = .pending
            let store = AccountStore()
            initialize(site: store.getAccounts().first?.sites.first)
        }
    }
}
