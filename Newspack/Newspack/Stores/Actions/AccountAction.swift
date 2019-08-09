import Foundation
import WordPressFlux

/// Supported Actions for changes to the Account
///
enum AccountAction: Action {
    case removeAccount(uuid: UUID)
    case accountRemoved
}
