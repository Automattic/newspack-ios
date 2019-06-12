import Foundation
import CoreData
import WordPressFlux

/// Supported Actions for changes to the SiteStore
///
enum SiteAction: Action {
    case create(url: String, settings: RemoteSiteSettings, accountID: UUID)
    case update(site: Site, settings: RemoteSiteSettings)
}

/// Dispatched actions to notifiy subscribers of changes
///
enum SiteEvent: Event {
    case siteCreated(site: Site?, error: Error?)
    case siteUpdated(site: Site?, error: Error?)
}

/// Errors
///
enum SiteError: Error {
    case createAccountMissing
}

/// Responsible for managing site related things.
///
class SiteStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let siteAction = action as? SiteAction else {
            return
        }
        switch siteAction {
        case .create(let url, let settings, let accountID):
            createSite(url: url, settings: settings, accountID: accountID)
        case .update(let site, let settings):
            updateSite(site: site, settings: settings)
        }
    }

}


extension SiteStore {

    /// Creates a new site with the specified .
    /// The new account is made the current account.
    ///
    /// - Parameters:
    ///     - url: The url of the site
    ///     - settings: The REST API auth token for the account.
    ///     - accountID: The UUID for the account to which the site belongs.
    ///
    func createSite(url: String, settings: RemoteSiteSettings, accountID: UUID) {

        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(accountID) else {
            emitChangeEvent(event: SiteEvent.siteCreated(site: nil, error: SiteError.createAccountMissing))
            return
        }

        let context = CoreDataManager.shared.mainContext
        let site = Site(context: context)
        site.url = url
        site.title = settings.title
        site.summary = settings.description
        site.timezone = settings.timezone
        site.dateFormat = settings.dateFormat
        site.timeFormat = settings.timeFormat
        site.startOfWeek = settings.startOfWeek
        site.language = settings.language
        site.useSmilies = settings.useSmilies
        site.defaultCategory = settings.defaultCategory
        site.defaultPostFormat = settings.defaultPostFormat
        site.postsPerPage = settings.postsPerPage
        site.defaultPingStatus = settings.defaultPingStatus
        site.defaultCommentStatus = settings.defaultCommentStatus

        site.account = account

        CoreDataManager.shared.saveContext()

        emitChangeEvent(event: SiteEvent.siteCreated(site: site, error: nil))
    }

    /// Update the specified site.
    ///
    /// - Parameters:
    ///   - site: the site to update
    ///   - settings: the remote settings containing the updates
    func updateSite(site: Site, settings: RemoteSiteSettings) {

        site.title = settings.title
        site.summary = settings.description
        site.timezone = settings.timezone
        site.dateFormat = settings.dateFormat
        site.timeFormat = settings.timeFormat
        site.startOfWeek = settings.startOfWeek
        site.language = settings.language
        site.useSmilies = settings.useSmilies
        site.defaultCategory = settings.defaultCategory
        site.defaultPostFormat = settings.defaultPostFormat
        site.postsPerPage = settings.postsPerPage
        site.defaultPingStatus = settings.defaultPingStatus
        site.defaultCommentStatus = settings.defaultCommentStatus
        CoreDataManager.shared.saveContext()

        emitChangeEvent(event: SiteEvent.siteUpdated(site: site, error: nil))
    }
}
