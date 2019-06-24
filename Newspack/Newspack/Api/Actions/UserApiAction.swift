import Foundation
import WordPressFlux

enum UserApiAction: Action {
    case accountFetched(user: RemoteUser?, error: Error?)
}
