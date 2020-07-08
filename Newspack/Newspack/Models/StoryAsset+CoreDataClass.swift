import Foundation
import CoreData

@objc(StoryAsset)
public class StoryAsset: NSManagedObject {

}

enum StoryAssetType: String {
    case textNote
    case image
    case video
    case audioNote
}
