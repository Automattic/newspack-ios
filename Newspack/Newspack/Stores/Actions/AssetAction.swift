import Foundation
import WordPressFlux

/// Supported Actions for changes to the AssetStore
///
enum AssetAction: Action {
    case sortMode(index: Int)
    case applyOrder(order: [UUID: Int])
    case createAssetFor(text: String)
    case deleteAsset(assetID: UUID)
}