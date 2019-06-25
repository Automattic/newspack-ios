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
        guard !action.isError() else {
            // TODO: Handle error.
            return
        }

        let accountStore = StoreContainer.shared.accountStore
        let siteStore = StoreContainer.shared.siteStore

        guard
            let user = action.payload,
            let account = accountStore.getAccountByUUID(action.accountUUID),
            let site =  siteStore.getSiteByUUID(action.siteUUID),
            account.sites.contains(site)
            else {
                //TODO: Unknown error?
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
