import Foundation
import CoreData
import WordPressFlux

/// Supported Actions for changes to the SiteStore
///
enum AccountDetailsAction: Action {
    case create(user: RemoteUser, accountID: UUID)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum AccountDetailsChange: Action {
    case accountDetailsCreated(details: AccountDetails)
}

/// Responsible for managing site related things.
///
class AccountDetailsStore: Store {

    let accountDetailsChangeDispatcher = Dispatcher<AccountDetailsChange>()

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let detailsAction = action as? AccountDetailsAction else {
            return
        }
        switch detailsAction {
        case .create(let user, let accountID):
            createAccountDetails(user: user, accountID: accountID)
        }
    }

}


extension AccountDetailsStore {

    /// Creates a new site with the specified .
    /// The new account is made the current account.
    ///
    /// - Parameters:
    ///     - url: The url of the site
    ///     - remoteSiteSettings: The REST API auth token for the account.
    ///
    func createAccountDetails(user: RemoteUser, accountID: UUID) {

        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(accountID) else {
            return
        }

        let context = CoreDataManager.shared.mainContext
        let details = AccountDetails(context: context)
        details.userID = user.id
        details.name = user.name
        details.firstName = user.firstName
        details.lastName = user.lastName
        details.nickname = user.nickname
        details.email = user.email
        details.avatarUrls = user.avatarUrls
        details.link = user.link
        details.locale = user.locale
        details.slug = user.slug
        details.summary = user.description
        details.url = user.url
        details.username = user.username
        details.registeredDate = user.registeredDate

        account.details = details

        CoreDataManager.shared.saveContext()

        accountDetailsChangeDispatcher.dispatch(.accountDetailsCreated(details: details))
    }
}
