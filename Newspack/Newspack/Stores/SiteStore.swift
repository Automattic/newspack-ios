import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class SiteStore: EventfulStore {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let siteAction = action as? SiteApiAction {
            switch siteAction {
            case .networkSitesFetched(let sites, let error):
                handleNetworkSitesFetched(sites: sites, error: error)
            case .siteFetched(let site, let error):
                handleSiteFetched(settings: site, error: error)
            }
        }

    }

}

extension SiteStore {

    func handleNetworkSitesFetched(sites: [RemoteSiteSettings]?, error: Error?) {
        // noop for now, pending other changes
    }


    /// Handles the siteFetched action.
    ///
    /// - Parameters:
    ///     - settings: The remote site settings
    ///     - error: Any error.
    ///
    func handleSiteFetched(settings: RemoteSiteSettings?, error: Error?) {
        guard let settings = settings else {
            if let _ = error {
                // TODO: Handle error
            }
            return
        }

        // TODO: This is tightly coupled to the current account and current site.
        // Need to find a way to inject the account and site.
        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.currentAccount else {
                return
        }

        let context = CoreDataManager.shared.mainContext

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
