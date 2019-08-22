import Foundation
import WordPressFlux

/// Supported Actions for changes to the EditCoordinator
///
enum EditAction: Action {
    case stageChanges(title: String, content: String)
    case autosave(title: String, content: String)
}
