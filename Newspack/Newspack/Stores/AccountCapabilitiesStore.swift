import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class AccountCapabilitiesStore: Store {

    private(set) var currentSiteID: UUID?

    init(dispatcher: ActionDispatcher = .global, siteID: UUID? = nil) {
        currentSiteID = siteID
        super.init(dispatcher: dispatcher)
    }
    
    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        if let apiAction = action as? AccountFetchedApiAction {
            handleAccountFetched(action: apiAction)
        }
    }
}

extension AccountCapabilitiesStore {

    /// Handles the accountFetched action.
    ///
    /// - Parameter action
    ///
    func handleAccountFetched(action: AccountFetchedApiAction) {
        guard !action.isError() else {
            // TODO: Handle error.
            if let error = action.error as NSError? {
                LogError(message: "handleAccountFetched: " + error.localizedDescription)
            }
            return
        }

        let siteStore = StoreContainer.shared.siteStore

        guard
            let user = action.payload,
            let siteID = currentSiteID,
            let siteObjID = siteStore.getSiteByUUID(siteID)?.objectID
            else {
                LogError(message: "handleAccountFetched: A value was unexpectedly nil.")
                return
        }

        CoreDataManager.shared.performOnWriteContext { [weak self] context in
            let site = context.object(with: siteObjID) as! Site
            let capabilities = site.capabilities ?? AccountCapabilities(context: context)

            self?.updateCapabilities(capabilities, with: user)
            capabilities.site = site
            CoreDataManager.shared.saveContext(context: context)

            DispatchQueue.main.async {
                self?.emitChange()
            }
        }
    }

    func updateCapabilities(_ capabilities: AccountCapabilities, with remoteUser: RemoteUser) {
        capabilities.roles = remoteUser.roles
        capabilities.capabilities = remoteUser.capabilities
    }
}
