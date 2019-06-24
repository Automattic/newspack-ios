import Foundation
import WordPressFlux

/// Supported Actions for Account Capabilities
///
enum AccountCapabilitiesAction: Action {
    case update(user: RemoteUser, siteUrl: String, accountID: UUID)
}
