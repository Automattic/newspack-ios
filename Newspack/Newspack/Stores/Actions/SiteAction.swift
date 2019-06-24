import Foundation
import WordPressFlux

/// Supported Actions for changes to the SiteStore
///
enum SiteAction: Action {
    case create(url: String, settings: RemoteSiteSettings, accountID: UUID)
    case update(site: Site, settings: RemoteSiteSettings)
}

