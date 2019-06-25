import Foundation
import WordPressFlux

struct AccountFetchedApiAction: ApiAction {
    var payload: RemoteUser?
    var error: Error?
    var accountUUID: UUID
    var siteUUID: UUID
}
