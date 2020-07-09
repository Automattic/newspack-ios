import Foundation
import CoreData

@objc(StoryAsset)
public class StoryAsset: NSManagedObject {

    public override func willSave() {
        super.willSave()

        updateSortedIfNeeded()
    }


    /// Called from willSave which will be called again if there are any changes
    /// so only update the property if necessary.
    ///
    func updateSortedIfNeeded() {
        let isSorted = order != -1
        if sorted == isSorted {
            return
        }
        sorted = isSorted
    }
}

enum StoryAssetType: String {
    case textNote
    case image
    case video
    case audioNote
}
