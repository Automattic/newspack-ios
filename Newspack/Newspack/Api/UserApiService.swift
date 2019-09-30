import Foundation
import WordPressFlux

class UserApiService: ApiService {

    let remote: UserServiceRemote

    override init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        remote = UserServiceRemote(wordPressComRestApi: api)
        super.init(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    func fetchMe() {
        LogInfo(message: "UserApiService.fetchMe")
        remote.fetchMe {[weak self] (user, error) in
            self?.dispatch(action: AccountFetchedApiAction(payload: user, error: error))
        }
    }

}
