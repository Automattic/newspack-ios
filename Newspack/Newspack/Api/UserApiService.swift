import Foundation
import WordPressFlux
import NewspackFramework

class UserApiService: ApiService {

    let remote: UserServiceRemote

    deinit {
        LogDebug(message: "UserApiService deinit")
    }

    override init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        remote = UserServiceRemote(wordPressComRestApi: api)
        super.init(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    func fetchMe() {
        LogInfo(message: "UserApiService.fetchMe")
        remote.fetchMe { (user, error) in
            self.dispatch(action: AccountFetchedApiAction(payload: user, error: error))
        }
    }

}
