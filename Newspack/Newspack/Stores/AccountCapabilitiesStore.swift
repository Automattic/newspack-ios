import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class AccountCapabilitiesStore: Store {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let apiAction = action as? UserApiAction {
            switch apiAction {
            case .accountFetched(let user, let error):
                handleAccountFetched(user: user, error: error)
            }
        }

    }

}

extension AccountCapabilitiesStore {

    /// Handles the accountFetched action.
    ///
    /// - Parameters:
    ///     - user: The remote user
    ///     - error: Any error.
    ///
    func handleAccountFetched(user: RemoteUser?, error: Error?) {
        guard let user = user else {
            if let _ = error {
                // TODO: Handle error
            }
            return
        }

        // TODO: This is tightly coupled to the current account and current site.
        // Need to find a way to inject the account and site.
        let accountStore = StoreContainer.shared.accountStore
        guard
            let account = accountStore.currentAccount,
            let site = account.currentSite else {
                return
        }

        let context = CoreDataManager.shared.mainContext
        let capabilities = site.capabilities ?? AccountCapabilities(context: context)
        capabilities.roles = user.roles
        capabilities.capabilities = user.capabilities
        capabilities.site = site

        CoreDataManager.shared.saveContext()

        emitChange()
    }

}
