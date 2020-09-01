import Foundation
import NewspackFramework

/// Responsible for persisting shadows of sites and stories for use by the
/// share extension.
///
class ShadowCaster {
    static let shared = ShadowCaster()
    private let manager = ShadowManager()

    private init() {}

    /// Build and store shadows of sites and stories from core data to shared defaults.
    ///
    func castShadows() {
        var shadows = [ShadowSite]()
        let store = StoreContainer.shared.siteStore
        let sites = store.getSites()
        for site in sites {
            var shadowStories = [ShadowStory]()
            for story in site.storyFolders {
                shadowStories.append(ShadowStory(uuid: story.uuid.uuidString, title: story.name, bookmarkData: story.bookmark))
            }
            shadows.append(ShadowSite(uuid: site.uuid.uuidString, title: site.title, stories: shadowStories))
        }

        manager.storeShadowSites(sites: shadows)
    }

}
