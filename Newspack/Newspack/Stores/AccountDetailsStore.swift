import Foundation
import CoreData
import WordPressFlux


/// Dispatched actions to notifiy subscribers of changes
///
enum AccountDetailsEvent: Event {
    case accountDetailsUpdated(details: AccountDetails?, error: Error?)
}

/// Errors
///
enum AccountDetailsError: Error {
    case createAccountMissing
}

/// Responsible for managing site related things.
///
class AccountDetailsStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let detailsAction = action as? AccountDetailsAction else {
            return
        }
        switch detailsAction {
        case .update(let user, let accountID):
            updateAccountDetails(user: user, accountID: accountID)
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
    func updateAccountDetails(user: RemoteUser, accountID: UUID) {

        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(accountID) else {
            emitChangeEvent(event: AccountDetailsEvent.accountDetailsUpdated(details: nil, error: AccountDetailsError.createAccountMissing))
            return
        }

        let context = CoreDataManager.shared.mainContext
        let details = account.details ?? AccountDetails(context: context)

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

        emitChangeEvent(event: AccountDetailsEvent.accountDetailsUpdated(details: details, error: nil))
    }
}
