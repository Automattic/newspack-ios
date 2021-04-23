import Foundation

/// Manages saving and retrieving shadow sites and assets from shared defaults
/// and wrangling files in shared storage.
///
public class ShadowManager {

    public static var shadowFolder: URL? {
        guard let groupFolder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            return nil
        }
        let url = groupFolder.appendingPathComponent(AppConstants.sharedAssetsFolderName, isDirectory: true)
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        do {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: false, attributes: nil)
        } catch  {
            return nil
        }
        return url
    }

    public init() {}

    /// Stores the passed array of shadow sites in shared defaults.
    /// This will overwrite whatever information is currently stored.
    ///
    /// - Parameter sites: An array of ShadowSite objects.
    ///
    public func storeShadowSites(sites: [ShadowSite]) {
        var arr = [[String: Any]]()

        for site in sites {
            arr.append(site.dictionary)
        }

        UserDefaults.shared.set(arr, forKey: AppConstants.shadowSitesKey)
    }

    /// Retrieve any stored shadow sites from shared defaults. This returned
    /// array should be considered non-cannonical and potentially out of date.
    /// Use with caution.
    ///
    /// - Returns: An array of shadow sites.
    ///
    public func retrieveShadowSites() -> [ShadowSite] {
        var sites = [ShadowSite]()

        guard let arr = UserDefaults.shared.object(forKey: AppConstants.shadowSitesKey) as? [[String: Any]] else {
            return sites
        }

        for dict in arr {
            sites.append(ShadowSite(dict: dict))
        }

        return sites
    }

    /// Store the supplied array of shadow assets in shared user defaults.
    /// Existing info in user defaults is retained.
    ///
    /// - Parameter assets: An array of shadow assets.
    ///
    public func storeShadowAssets(assets: [ShadowAsset]) {
        var shadows = assets
        shadows.append(contentsOf: retrieveShadowAssets())

        var arr = [[String: Any]]()
        for shadow in shadows {
            arr.append(shadow.dictionary)
        }

        UserDefaults.shared.set(arr, forKey: AppConstants.shadowAssetsKey)
    }

    /// Retrieves the array of shadow assets currently stored in shared user defaults.
    ///
    /// - Returns: An array of shadow assets.
    ///
    public func retrieveShadowAssets() -> [ShadowAsset] {
        var arr = [ShadowAsset]()

        if let existing = UserDefaults.shared.object(forKey: AppConstants.shadowAssetsKey) as? [[String: Any]] {
            for dict in existing {
                arr.append(ShadowAsset(dict: dict))
            }
        }

        return arr
    }

    /// Removes the shadow asset dictionary fron shared defaults and
    /// removes all files from shared storage.
    ///
    public func clearShadowAssets() {
        // Purge stored defaults.
        UserDefaults.shared.removeObject(forKey: AppConstants.shadowAssetsKey)

        guard let folderURL = ShadowManager.shadowFolder else {
            LogWarn(message: "Unable to retrieve group asset share directory URL.")
            return
        }

        // Purge stored files.
        let manager = FolderManager(rootFolder: folderURL)
        if !manager.deleteContentsOfFolder(folder: folderURL) {
            LogWarn(message: "There was an error deleting shadow asset files.")
        }
    }

}
