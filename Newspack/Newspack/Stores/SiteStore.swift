import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class SiteStore: Store {

    private(set) var currentSiteID: UUID?

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID
        super.init(dispatcher: dispatcher)
    }

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
            let error = error as NSError
            LogError(message: "getSiteByUUID: " + error.localizedDescription)
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
            if let error = action.error as NSError? {
                LogError(message: "handleSiteFetched: " + error.localizedDescription)
            }
            return
        }

        guard
            let settings = action.payload,
            let siteID = currentSiteID,
            let siteObjID = getSiteByUUID(siteID)?.objectID
            else {
                LogError(message: "handleSiteFetched: A value was unexpectedly nil.")
                return
        }

        CoreDataManager.shared.performOnWriteContext { [weak self] (context) in
            let site = context.object(with: siteObjID) as! Site
            self?.updateSite(site: site, withSettings: settings)
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.emitChange()
            }
        }
    }

    // TODO: It would be nice to not need a special method to handle site creation
    // during the intial set up process. There should be a way to rely on
    // flux instead.
    func createSite(url: String, settings: RemoteSiteSettings, accountID: UUID) {
        let accountStore = StoreContainer.shared.accountStore
        guard let accountObjID = accountStore.getAccountByUUID(accountID)?.objectID else {
            // TODO: handle error
            LogError(message: "createSite: Unable to find account by UUID.")
            return
        }

        CoreDataManager.shared.performOnWriteContext { [weak self] (context) in
            let account = context.object(with: accountObjID) as! Account
            let site = Site(context: context)
            site.account = account
            site.uuid = UUID()
            site.url = url

            self?.updateSite(site: site, withSettings: settings)

            CoreDataManager.shared.saveContext(context: context)
        }
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
