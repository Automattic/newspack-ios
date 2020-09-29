import Foundation
import CoreData

@objc(StoryFolder)
public class StoryFolder: NSManagedObject, StoryCellProvider {

    var textNotes: [StoryAsset] {
        let items = assets.filter { (asset) -> Bool in
            asset.assetType == .textNote
        }
        return Array(items)
    }

    var videos: [StoryAsset] {
        let items = assets.filter { (asset) -> Bool in
            asset.assetType == .video
        }
        return Array(items)
    }

    var images: [StoryAsset] {
        let items = assets.filter { (asset) -> Bool in
            asset.assetType == .image
        }
        return Array(items)
    }

    var audioNotes: [StoryAsset] {
        let items = assets.filter { (asset) -> Bool in
            asset.assetType == .audioNote
        }
        return Array(items)
    }

    var needsSync: Bool {
        return synced < modified
    }

    var textNoteCount: Int {
        return textNotes.count
    }

    var imageCount: Int {
        return images.count
    }

    var videoCount: Int {
        return videos.count
    }

    var audioNoteCount: Int {
        return audioNotes.count
    }

}
