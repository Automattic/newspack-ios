import Foundation
import WordPressFlux

class SiteApiService: ApiService {

    let remote: SiteServiceRemote

    override init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        remote = SiteServiceRemote(wordPressComRestApi: api)
        super.init(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    func fetchSitesForNetwork() {
        LogInfo(message: "SiteApiService.fetchSitesForNetwork")
        remote.fetchSitesForNetwork { [weak self] (sites, error) in
            self?.dispatch(action: NetworkSitesFetchedApiAction(payload: sites, error: error))
        }
    }

    func fetchSiteSettings() {
        LogInfo(message: "SiteApiService.fetchSiteSettings")
        remote.fetchSiteSettings { [weak self] (settings, error) in
            self?.dispatch(action: SiteFetchedApiAction(payload: settings, error: error))
        }
    }
}
