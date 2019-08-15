import Foundation
import Gutenberg
import Aztec

/// Provides a bridge between the Editor, and the content being edited.
///
class EditCoordinator {

    var post: Post?

    init(post: Post?) {
        self.post = post
    }

}

extension EditCoordinator: GutenbergBridgeDataSource {
    func gutenbergInitialContent() -> String? {
        return post?.content ?? ""
    }

    func gutenbergInitialTitle() -> String? {
        return post?.title ?? ""
    }

    func aztecAttachmentDelegate() -> TextViewAttachmentDelegate {
        return EditorAttachmentDelegate()
    }

    func gutenbergLocale() -> String? {
        // TODO: Use system locale
        return "en"
    }

    func gutenbergTranslations() -> [String : [String]]? {
        return nil
    }
}
