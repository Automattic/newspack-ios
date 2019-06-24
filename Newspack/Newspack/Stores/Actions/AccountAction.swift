import Foundation
import WordPressFlux

/// Supported Actions for changes to the Account
///
enum AccountAction: Action {
    case setCurrentAccount(account: Account)
    case setCurrentSite(site: Site, account: Account)
}
