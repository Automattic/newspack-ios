import Foundation
import CoreData
import WordPressFlux

/// Supported Actions for changes to the SiteStore
///
enum AccountCapabilitiesAction: Action {
    case create(remoteUser: RemoteUser, siteUrl: String, accountID: UUID)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum AccountCapabilitiesEvent: Event {
    case accountCapabilitiesCreated(capabilities: AccountCapabilities)
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
        case .create(let user, let siteUrl, let accountID):
            createAccountCapabilities(user: user, siteUrl: siteUrl, accountID: accountID)
        }
    }

}


extension AccountCapabilitiesStore {

    /// Creates a new site with the specified .
    /// The new account is made the current account.
    ///
    /// - Parameters:
    ///     - user: The remote user
    ///     - siteUrl: The url of the site
    ///     - accountID: UUID for the account
    ///
    func createAccountCapabilities(user: RemoteUser, siteUrl: String, accountID: UUID) {

        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(accountID) else {
            return
        }

        let sites = account.sites.filter { (site) -> Bool in
            return site.url == siteUrl
        }
        guard let site = sites.first else {
            return
        }

        let context = CoreDataManager.shared.mainContext
        let capabilities = AccountCapabilities(context: context)
        capabilities.roles = user.roles
        capabilities.capabilities = user.capabilities
        capabilities.site = site

        CoreDataManager.shared.saveContext()

        emitChangeEvent(event: AccountCapabilitiesEvent.accountCapabilitiesCreated(capabilities: capabilities))
    }
}
