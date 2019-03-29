import Foundation
import CoreData
import KeychainAccess
import WordPressFlux

/// Supported Actions for changes to the AccountStore
///
enum AccountAction: Action {
    case create(authToken: String)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum AccountChange: Action {
    case accountCreated(account: Account)
}

/// Responsible for managing account and keychain related things.
///
class AccountStore: Store {
    private static let keychainServiceName: String = "com.automattic.newspack"
    private let keychain: Keychain

    let accountChangeDispatcher = Dispatcher<AccountChange>()

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
        case .create(let authToken):
            createAccount(authToken: authToken)
        }
    }
}

extension AccountStore {
    /// Returns the number of accounts currently in the app.
    ///
    func numberOfAccounts() -> Int {
        let fetchRequest = Account.accountFetchRequest()
        let context = CoreDataManager.shared.mainContext
        let count = (try? context.count(for: fetchRequest)) ?? 0
        return count
    }

}

extension AccountStore {

    /// Creates a new account with the specified username and auth token
    ///
    /// - Parameters:
    ///     - authToken: The REST API auth token for the account.
    ///
    func createAccount(authToken: String) {
        let context = CoreDataManager.shared.mainContext
        let account = Account(context: context)
        account.uuid = UUID()
        CoreDataManager.shared.saveContext()

        setAuthToken(authToken, for: account)

        accountChangeDispatcher.dispatch(.accountCreated(account: account))
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
