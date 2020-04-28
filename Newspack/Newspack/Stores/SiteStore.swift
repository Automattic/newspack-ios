import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class SiteStore: Store, FolderMaker {

    private(set) var currentSiteID: UUID? {
        didSet {
            // Note: didSet is never called during init.
            createSiteFolderIfNeeded()
        }
    }

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID
        super.init(dispatcher: dispatcher)

        createSiteFolderIfNeeded()
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

    /// Creates a folder for the current site if one does not exist. The site
    /// folder contains all story folders so it must exist prior to creating
    /// story folders.
    ///
    func createSiteFolderIfNeeded() {
        guard
            let siteID = currentSiteID,
            let site = getSiteByUUID(siteID)
        else {
            return
        }

        // TODO: Before creating the folder, check the site's siteFolder bookmark
        // to see if one already exists. If so do not create a new one.


        // Get a usable site title
        let name = folderNameForSite(site: site)
        let folderManager = SessionManager.shared.folderManager

        guard let url = folderManager.createFolderAtPath(path: name) else {
            fatalError("Unable to create a folder named: \(name)")
        }

        // The FolderManager's currentFolder should _always_ be the site's folder.
        guard folderManager.setCurrentFolder(url: url) else {
            fatalError("Unable to set the folder manager's current folder to \(url.path)")
        }

    }
}

extension SiteStore {

    /// Get a folder name for the specified site.
    ///
    /// - Parameter site: A Site instance.
    /// - Returns: A string that should be usable as a folder name.
    ///
    func folderNameForSite(site: Site) -> String {
        // Prefer using the URL host + path since this should be unique
        // for every site, and still readable if the user looks at the folder itself.
        if
            let url = URL(string: site.url),
            let host = url.host
        {
            let name = host + url.path
            return sanitizedFolderName(name: name)
        }

        // If for some crazy reason the URL is not available, use the site's UUID.
        // The UUID will be unique, even if it looks like nonsense to the user.
        // We want to avoid using the site's title as this is not guarenteed to
        // be unique and there could be collisions when there are multiple sites.
        // We can be clever later and use the site's title as a directory's
        // display name.
        return site.uuid.uuidString
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
    func createSites(sites: [RemoteSiteSettings], accountID: UUID, onComplete:(() -> Void)? = nil) {
        let accountStore = StoreContainer.shared.accountStore
        guard let accountObjID = accountStore.getAccountByUUID(accountID)?.objectID else {
            // TODO: handle error
            LogError(message: "createSite: Unable to find account by UUID.")
            return
        }

        CoreDataManager.shared.performOnWriteContext { [weak self] (context) in
            let account = context.object(with: accountObjID) as! Account
            for settings in sites {
                let site = Site(context: context)
                site.account = account
                site.uuid = UUID()

                self?.updateSite(site: site, withSettings: settings)
            }

            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                onComplete?()
            }
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
        site.url = settings.url
    }
}
