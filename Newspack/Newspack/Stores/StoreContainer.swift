import Foundation

/// A singleton providing a single point of reference to various stores.
///
class StoreContainer {
    static let shared = StoreContainer()

    let accountStore = AccountStore()
    let accountCapabilitiesStore = AccountCapabilitiesStore()
    let accountDetailsStore = AccountDetailsStore()
    let siteStore = SiteStore()
    let postStore = PostStore()
}
