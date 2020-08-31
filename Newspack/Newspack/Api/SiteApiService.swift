import Foundation
import WordPressFlux
import NewspackFramework

class SiteApiService: ApiService {

    let remote: SiteServiceRemote

    deinit {
        LogDebug(message: "SiteApiService deinit")
    }

    override init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        remote = SiteServiceRemote(wordPressComRestApi: api)
        super.init(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    func fetchSitesForNetwork() {
        LogInfo(message: "SiteApiService.fetchSitesForNetwork")
        remote.fetchSitesForNetwork { (sites, error) in
            self.dispatch(action: NetworkSitesFetchedApiAction(payload: sites, error: error))
        }
    }

    func fetchSiteSettings() {
        LogInfo(message: "SiteApiService.fetchSiteSettings")
        remote.fetchSiteSettings { (settings, error) in
            self.dispatch(action: SiteFetchedApiAction(payload: settings, error: error))
        }
    }
}
