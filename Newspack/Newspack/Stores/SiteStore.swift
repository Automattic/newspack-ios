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

    /// Get the site for the specified UUID
    ///
    /// - Parameter uuid: The site's UUID
    /// - Returns: The site
    ///
    func getSiteByUUID(_ uuid: UUID) -> Site? {
        let fetchRequest = Site.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        let context = CoreDataManager.shared.mainContext
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            // TODO: Need to log this
            let error = error as NSError
            print(error.localizedDescription)
        }
        return nil
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
        guard !action.isError() else {
            // TODO: Handle error.
            return
        }

        let accountStore = StoreContainer.shared.accountStore

        guard
            let account = accountStore.getAccountByUUID(action.accountUUID),
            let settings = action.payload
            else {
                // TODO: Unknown error?
                return
        }

        let context = CoreDataManager.shared.mainContext

        let site: Site
        if  let siteUUID = action.siteUUID,
            let maybeSite = getSiteByUUID(siteUUID),
            account.sites.contains(maybeSite) {
                site = maybeSite
        } else {
            site = Site(context: context)
            site.account = account
        }

//        site.url = url
        site.url = account.networkUrl // TODO: fix this.

        updateSite(site: site, withSettings: settings)

        CoreDataManager.shared.saveContext()

        emitChange()
    }

    // TODO: It would be nice to not need a special method to handle site creation
    // during the intial set up process. There should be a way to rely on
    // flux instead.
    func createSite(url: String, settings: RemoteSiteSettings, accountID: UUID) {
        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(accountID) else {
            return
        }

        let context = CoreDataManager.shared.mainContext
        let site = Site(context: context)
        site.account = account
        site.url = url

        updateSite(site: site, withSettings: settings)

        CoreDataManager.shared.saveContext()
    }


    func updateSite(site: Site, withSettings settings: RemoteSiteSettings) {
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
    }
}
