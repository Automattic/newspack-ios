import Foundation
import CoreData

@objc(StoryAsset)
public class StoryAsset: NSManagedObject, TextNoteCellProvider, PhotoCellProvider, VideoCellProvider, AudioCellProvider {

    var caption: String! {
        return ""
    }

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

    func displayName() -> String {
        switch self {
        case .textNote:
            return NSLocalizedString("Text Note", comment: "Noun. A short note made up of simple text.")
        case .image:
            return NSLocalizedString("Image", comment: "Noun. An image or photo.")
        case .video:
            return NSLocalizedString("Video", comment: "Noun. A video recording.")
        case .audioNote:
            return NSLocalizedString("Audio Note", comment: "Noun: A short audio recording. Like a text note but audio, likely the user's own voice.")

        }
    }
}
