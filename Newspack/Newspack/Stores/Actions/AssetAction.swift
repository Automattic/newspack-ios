import Foundation
import Photos
import WordPressFlux

/// Supported Actions for changes to the AssetStore
///
enum AssetAction: Action {
    case sortMode(index: Int)
    case sortDirection(ascending: Bool)
    case createAssetFor(text: String)
    case updateText(assetID: UUID, text: String)
    case deleteAsset(assetID: UUID)
    case importMedia(assets: [PHAsset])
    case updateCaption(assetID: UUID, caption: String)
    case updateAltText(assetID: UUID, altText: String)
    case flagToUpload(assetID: UUID)
}
