import Foundation
import CoreData
import KeychainAccess
import WordPressFlux
import NewspackFramework

/// Responsible for managing account and keychain related things.
///
class AccountStore: Store {

    private let currentAccountUUIDKey: String = "currentAccountUUIDKey"
    private static let keychainServiceName: String = "com.automattic.newspack"
    private let keychain: Keychain

    /// Initializer
    ///
    private(set) var currentAccountID: UUID?

    init(dispatcher: ActionDispatcher = .global, accountID: UUID? = nil, keychainServiceName: String = AccountStore.keychainServiceName) {
        currentAccountID = accountID
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
        super.init(dispatcher: dispatcher)

        syncAccount()
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let accountAction = action as? AccountAction else {
            return
        }
        
        switch accountAction {
        case .removeAccount(let uuid):
            removeAccount(uuid: uuid)
        case .accountRemoved:
            break
        }
    }
}

extension AccountStore {

    /// Read only. Convenience property for getting the current account for the current session.
    ///
    var currentAccount: Account? {
        get {
            return SessionManager.shared.currentSite?.account
        }
    }

    /// Get the account for the specified UUID
    ///
    /// - Parameter uuid: The account's UUID
    /// - Returns: The account
    ///
    func getAccountByUUID(_ uuid: UUID) -> Account? {
        let fetchRequest = Account.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        let context = CoreDataManager.shared.mainContext
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            let error = error as NSError
            LogError(message: "getAccountByUUID: " + error.localizedDescription)
        }
        return nil
    }

    /// Get all accounts
    ///
    /// - Returns: An array of Accounts. The array may be empty.
    ///
    func getAccounts() -> [Account] {
        let fetchRequest = Account.defaultFetchRequest()
        let context = CoreDataManager.shared.mainContext
        do {
            let accounts = try context.fetch(fetchRequest)
            return accounts
        } catch {
            let error = error as NSError
            LogError(message: "getAccounts: " + error.localizedDescription)
        }
        return [Account]()
    }

    /// Get the number of accounts currently in the app.
    ///
    /// - Returns: The number of accounts.
    ///
    func numberOfAccounts() -> Int {
        let fetchRequest = Account.defaultFetchRequest()
        let context = CoreDataManager.shared.mainContext
        let count = (try? context.count(for: fetchRequest)) ?? 0
        return count
    }

}

extension AccountStore {

    /// Creates a new account with the specified username and auth token.
    /// The new account is made the current account.
    ///
    /// - Parameters:
    ///     - authToken: The REST API auth token for the account.
    ///
    @discardableResult
    func createAccount(authToken: String, forNetworkAt url: String) -> Account {
        let uuid = UUID()

        // This block passed to performOnWriteContextAndWait will be executed
        // on the calling thread, which is the main thread in this case, even
        // tho writeContext will be the NSManagedObjectContext used.
        CoreDataManager.shared.performOnWriteContextAndWait { (context) in
            assert(Thread.isMainThread)
            let account = Account(context: context)
            account.uuid = uuid
            account.networkUrl = url
            CoreDataManager.shared.saveContext(context: context)
        }

        let account = getAccountByUUID(uuid)!
        setAuthToken(authToken, for: account)
        return account
    }


    /// Handles the .removeAccount action. Sets currentAccount to a remaining account or nil.
    ///
    /// - Parameter uuid: The uuid of the account to remove.
    ///
    func removeAccount(uuid: UUID) {
        guard let account = getAccountByUUID(uuid) else {
            LogError(message: "removeAccount: Unable to find account by UUID.")
            return
        }

        // For each site, clean up its site folder before deleting the account.
        let folderManager = SessionManager.shared.folderManager
        for site in account.sites {
            var isStale = false
            if let url = folderManager.urlFromBookmark(bookmark: site.siteFolder, bookmarkIsStale: &isStale), !isStale {
                folderManager.deleteFolder(at: url)
            }
        }

        let accountObjID = account.objectID
        CoreDataManager.shared.performOnWriteContext { (context) in
            let account = context.object(with: accountObjID) as! Account
            context.delete(account)
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                ActionDispatcher.global.dispatch(AccountAction.accountRemoved)
            }
        }
    }
}


/// Auth token management
extension AccountStore {

    /// Get the auth token for the spedified account.
    ///
    /// - Parameter:
    ///   - account: The account.
    /// - Returns: The auth token.
    ///
    func getAuthTokenForAccount(_ account: Account) -> String? {
        return keychain[account.uuid.uuidString]
    }

    /// Store the specified auth token for the specified account.
    ///
    /// - Parameters:
    ///   - token: The auth token.
    ///   - account: The account.
    ///
    func setAuthToken(_ token: String, for account: Account) {
        keychain[account.uuid.uuidString] = token
    }

    /// Clear the auth token for the specified account.
    ///
    /// - Parameters:
    ///   - account: The account.
    ///
    func clearAuthTokenForAccount(_ account: Account) {
        keychain[account.uuid.uuidString] = nil
    }

    /// Clear all stored auth tokens.
    ///
    func clearAuthTokens() {
        try? keychain.removeAll()
    }
}

// MARK: - API Related.
extension AccountStore {

    func syncAccount() {
        guard let _ = currentAccount else {
            return
        }

        let service = ApiService.userService()
        service.fetchMe()
    }

}
