import Foundation

public class ShadowManager {

    // Creates a cannonical copy
    public func storeSiteShadows() {
        // create empty shadow array
        // Get sites
        // for each site
        // get folders
        // for each folder
        // generate shadow folder
        // generate shadow site
        // get shadow site dictionary
        // add shadow site dictionary to shadow array
        // save shadow array in user defaults
    }

    // Creates an non-cannonical copy based on the last saved info. Might be out of date.
    public func retrieveSiteShadows() {
        // Get shadow array from user defaults
        // create Shadow Site array
        // for each shadow site dictionary in the shadow array
        // create a shadowsite from the dictionary
        // add the shadow site to the shadow site array
    }

    // Store shadow assets in group user defaults
    public func storeShadowAssets(assets: [ShadowAsset]) {
        // retrieve array of existing shadow assets from user defaults, or create new array
        // for each asset
        // get asset dictionary
        // add to shadow array
        // save shadow array to user defaults
    }

    // Retrieve shadow assets from group user defaults
    public func retrieveShadowAssets() {
        // create shadow asset array
        // retrieve array of existing shadow assets from user defaults, or create new array
        // for item in array
        // create shadow asset from dict
        // add shadow asset to shadow asset array
        // return
    }

    // TODO: Write file to group folder and return file URL.
    public func saveInGroupStorage(rawAsset: Any) -> Data? {
        // create group storage if needed.
        return nil
    }

    // Remove all shadow assets. Do this after importing.

    /// Removes the shadow asset dictionary fron shared defaults and
    /// removes all files from shared storage.
    ///
    public func clearShadowAssets() {
        UserDefaults.shared.removeObject(forKey: AppConstants.shadowAssetsKey)
        //TODO: remove files from shared storage.
    }

}
