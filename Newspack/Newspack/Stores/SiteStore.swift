import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class SiteStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let apiAction = action as? NetworkSitesFetchedApiAction {
            handleNetworkSitesFetched(action: apiAction)
        } else if let apiAction = action as? SiteFetchedApiAction {
            handleSiteFetched(action: apiAction)
        }

    }

}

extension SiteStore {

    func handleNetworkSitesFetched(action: NetworkSitesFetchedApiAction) {
        // noop for now, pending other changes
    }


    /// Handles the siteFetched action.
    ///
    /// - Parameters:
    ///     - settings: The remote site settings
    ///     - error: Any error.
    ///
    func handleSiteFetched(action: SiteFetchedApiAction) {
        guard let settings = action.payload else {
            if let _ = action.error {
                // TODO: Handle error
            }
            return
        }

        // TODO: This is tightly coupled to the current account and current site.
        // Need to find a way to inject the account and site.
        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(action.accountUUID) else {
            return
        }

        let context = CoreDataManager.shared.mainContext

        // TODO rely on UUID to fetch existing site and assign UUID to new site
        let site = account.currentSite ?? Site(context: context)
//        site.url = url
        site.url = account.networkUrl // TODO: fix this.
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

        emitChange()
    }

}
