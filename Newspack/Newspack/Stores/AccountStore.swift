import Foundation
import CoreData
import KeychainAccess
import WordPressFlux

/// Supported Actions for changes to the AccountStore
///
enum AccountAction: Action {
    case create(authToken: String, networkUrl: String)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum AccountEvent: Event {
    case accountCreated(account: Account)
    case currentAccountChanged
}

/// Responsible for managing account and keychain related things.
///
class AccountStore: EventfulStore {
    private let currentAccountUUIDKey: String = "currentAccountUUIDKey"
    private static let keychainServiceName: String = "com.automattic.newspack"
    private let keychain: Keychain

    /// Initializer
    ///
    init(dispatcher: ActionDispatcher = .global, keychainServiceName: String = AccountStore.keychainServiceName) {
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
        super.init(dispatcher: dispatcher)
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let accountAction = action as? AccountAction else {
            return
        }
        switch accountAction {
        case .create(let authToken, let networkUrl):
            createAccount(authToken: authToken, forNetworkAt: networkUrl)
        }
    }
}

extension AccountStore {

    /// Get or set the current account.
    ///
    var currentAccount: Account? {
        get {
            guard
                let uuidString = UserDefaults.standard.string(forKey: currentAccountUUIDKey),
                let uuid = UUID(uuidString: uuidString),
                let account = getAccountByUUID(uuid)
                else {
                    // Womp womp.
                    return nil
            }
            return account
        }
        set(account) {
            if account == currentAccount {
                return
            }

            let defaults = UserDefaults.standard

            defer {
                defaults.synchronize()
                emitChangeEvent(event: AccountEvent.currentAccountChanged)
            }

            guard let account = account else {
                defaults.removeObject(forKey: currentAccountUUIDKey)
                return
            }
            defaults.set(account.uuid.uuidString, forKey: currentAccountUUIDKey)
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
            let accounts = try context.fetch(fetchRequest)
            return accounts.first
        } catch {
            let error = error as NSError
            print(error.localizedDescription)
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
            print(error.localizedDescription)
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
    func createAccount(authToken: String, forNetworkAt url: String) {
        let context = CoreDataManager.shared.mainContext
        let account = Account(context: context)
        account.uuid = UUID()
        account.networkUrl = url

        CoreDataManager.shared.saveContext()

        setAuthToken(authToken, for: account)

        emitChangeEvent(event: AccountEvent.accountCreated(account: account))

        // Emits change
        currentAccount = account
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
