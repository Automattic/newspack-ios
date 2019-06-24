import Foundation
import CoreData
import WordPressFlux

/// Dispatched actions to notifiy subscribers of changes
///
enum AccountCapabilitiesEvent: Event {
    case accountCapabilitiesUpdated(capabilities: AccountCapabilities?, error: Error?)
}

/// Errors
///
enum AccountCapabilitiesError: Error {
    case updateAccountMissing
    case updateSiteMissing
}

/// Responsible for managing site related things.
///
class AccountCapabilitiesStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let capabilitiesAction = action as? AccountCapabilitiesAction else {
            return
        }
        switch capabilitiesAction {
        case .update(let user, let siteUrl, let accountID):
            updateAccountCapabilities(user: user, siteUrl: siteUrl, accountID: accountID)
        }
    }

}


extension AccountCapabilitiesStore {

    /// Update the account capabilities for a site.
    /// The new account is made the current account.
    ///
    /// - Parameters:
    ///     - user: The remote user
    ///     - siteUrl: The url of the site
    ///     - accountID: UUID for the account
    ///
    func updateAccountCapabilities(user: RemoteUser, siteUrl: String, accountID: UUID) {
        // Find the account
        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(accountID) else {
            emitChangeEvent(event: AccountCapabilitiesEvent.accountCapabilitiesUpdated(capabilities: nil, error: AccountCapabilitiesError.updateAccountMissing))
            return
        }
        // Find the site
        let sites = account.sites.filter { (site) -> Bool in
            return site.url == siteUrl
        }
        guard let site = sites.first else {
            emitChangeEvent(event: AccountCapabilitiesEvent.accountCapabilitiesUpdated(capabilities: nil, error: AccountCapabilitiesError.updateSiteMissing))
            return
        }

        let context = CoreDataManager.shared.mainContext
        let capabilities = AccountCapabilities(context: context)
        capabilities.roles = user.roles
        capabilities.capabilities = user.capabilities
        capabilities.site = site

        CoreDataManager.shared.saveContext()

        emitChangeEvent(event: AccountCapabilitiesEvent.accountCapabilitiesUpdated(capabilities: capabilities, error: nil))
    }
}
