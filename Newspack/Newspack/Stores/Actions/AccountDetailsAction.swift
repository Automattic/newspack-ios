import Foundation
import WordPressFlux

/// Supported Actions for changes to Account Details
///
enum AccountDetailsAction: Action {
    case update(user: RemoteUser, accountID: UUID)
}
