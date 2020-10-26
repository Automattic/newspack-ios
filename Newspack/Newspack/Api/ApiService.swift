import Foundation
import WordPressFlux

/// Base class for API services.  Provides static factory methods for convenience.
///
class ApiService {

    /// Get an instance of the UserApiService
    ///
    /// - Returns: UserApiService
    ///
    static func userService() -> UserApiService {
        let api = SessionManager.shared.api
        let dispatcher = SessionManager.shared.sessionDispatcher
        return UserApiService(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    /// Get an instance of the SiteApiService
    ///
    /// - Returns: SiteApiService
    ///
    static func siteService() -> SiteApiService {
        let api = SessionManager.shared.api
        let dispatcher = SessionManager.shared.sessionDispatcher
        return SiteApiService(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    let api:WordPressCoreRestApi
    let dispatcher: ActionDispatcher

    init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        self.api = api
        self.dispatcher = dispatcher
    }

    func dispatch(action: Action) {
        dispatcher.dispatch(action)
    }
}
