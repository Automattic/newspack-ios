import Foundation
import CoreData
import CoreServices

@objc(StoryAsset)
public class StoryAsset: NSManagedObject, TextNoteCellProvider, PhotoCellProvider, VideoCellProvider, AudioCellProvider {

    var needsManualUpload: Bool {
        // A remote ID means the asset is already uploaded.
        // Text notes do not have files to upload.
        if remoteID > 0 || assetType == .textNote {
            return false
        }
        return !folder.autoSyncAssets
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

    /// Return the type of asset for the specified mimeType. TextNotes do not have
    /// backing files so .textNote is not a valid result.
    ///
    /// - Parameter mimeType: A string representing a mime type.
    /// - Returns: The type of asset for the mime type or nil if there was no match.
    ///
    static func typeFromMimeType(mimeType: String) -> StoryAssetType? {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as NSString, nil)?.takeRetainedValue() as NSString? else {
            return nil
        }

        if UTTypeConformsTo(uti, kUTTypeImage) {
            return .image
        }

        if UTTypeConformsTo(uti, kUTTypeVideo) {
            return .video
        }

        if UTTypeConformsTo(uti, kUTTypeAudio) {
            return .audioNote
        }

        return nil
    }

}
