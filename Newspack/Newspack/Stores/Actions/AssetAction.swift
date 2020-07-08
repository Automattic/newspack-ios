import Foundation
import WordPressFlux

/// Supported Actions for changes to the AssetStore
///
enum AssetAction: Action {
    case createAssetFor(text: String)
    case deleteAsset(assetID: UUID)
}
