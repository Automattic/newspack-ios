import Foundation
import CoreData
import KeychainAccess
import WordPressFlux

/// Supported Actions for changes to the AccountStore
///
enum AccountAction: Action {
    case create(username: String, authToken: String)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum AccountChange: Action {
    case accountCreated(account: Account)
}

/// Responsible for managing account and keychain related things.
///
class AccountStore: Store {

    private let keychainServiceName = "com.automattic.newspack"
    private let keychain: Keychain

    let accountChangeDispatcher = Dispatcher<AccountChange>()

    /// Initializer
    ///
    override init(dispatcher: ActionDispatcher = .global) {
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
        case .create(let username, let authToken):
            createAccount(username: username, authToken: authToken)
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

    /// Returns the auth token for the specified account.
    ///
    /// - Parameters:
    ///     - account: An Account instance
    ///
    func authToken(for account: Account) -> String? {
        return keychain[account.objectID.uriRepresentation().absoluteString]
    }
}

extension AccountStore {

    /// Creates a new account with the specified username and auth token
    ///
    /// - Parameters:
    ///     - username: The username for the account.
    ///     - authToken: The REST API auth token for the account.
    ///
    func createAccount(username: String, authToken: String) {
        let context = CoreDataManager.shared.mainContext
        let account = Account(context: context)
        account.username = username

        // TODO: Refactor to avoid the try!
        try! context.obtainPermanentIDs(for: [account])
        keychain[account.objectID.uriRepresentation().absoluteString] = authToken
        CoreDataManager.shared.saveContext()
        accountChangeDispatcher.dispatch(.accountCreated(account: account))
    }
}
