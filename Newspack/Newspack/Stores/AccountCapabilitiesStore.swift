import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class AccountCapabilitiesStore: Store {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let apiAction = action as? AccountFetchedApiAction {
            handleAccountFetched(action: apiAction)
        }

    }

}

extension AccountCapabilitiesStore {

    /// Handles the accountFetched action.
    ///
    /// - Parameter action
    ///
    func handleAccountFetched(action: AccountFetchedApiAction) {
        if action.isError() {
            // TODO: Handle error
        }

        let accountStore = StoreContainer.shared.accountStore
        // TODO: get site by siteUUID
        guard
            let user = action.payload,
            let account = accountStore.getAccountByUUID(action.accountUUID),
            let site = account.currentSite
            else {
                //TODO:
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
