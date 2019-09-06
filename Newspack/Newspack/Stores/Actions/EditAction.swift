import Foundation
import WordPressFlux

/// Supported Actions for changes to the EditCoordinator
///
enum EditAction: Action {
    case stageChanges(title: String, content: String)
    case autosave(title: String, content: String)
}

enum PostSaveAction: Action {
    case publish
    case publishPrivately
    case saveAsDraft
    case saveAsPending
    case trash
}
