import Foundation
import WordPressFlux
import Gutenberg
import Aztec

/// Provides a bridge between the Editor, and the content being edited.
///
class EditCoordinator: Store {

    var postItem: PostListItem?
    let stagedEdits: StagedEdits
    var draftUUID: UUID?

    init(postItem: PostListItem?, dispatcher: ActionDispatcher) {
        self.postItem = postItem
        self.stagedEdits = postItem?.stagedEdits ?? StagedEdits(context: CoreDataManager.shared.mainContext)
        super.init(dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        if let apiAction = action as? PostCreatedApiAction {
            handlePostCreatedApiAction(action: apiAction)
        } else if let apiAction = action as? AutosaveApiAction {
            handleAutosaveApiAction(action: apiAction)
        } else if let apiAction = action as? PostUpdatedApiAction {
            handlePostUpdatedApiAction(action: apiAction)
        }

        guard let editAction = action as? EditAction else {
            return
        }

        switch editAction {
        case .autosave(let title, let content):
            handleAutosaveAction(title: title, content: content)
        case .stageChanges(let title, let content):
            handleStageChangesAction(title: title, content: content)
        }
    }

    func handleStageChangesAction(title: String, content: String) {
        stagedEdits.title = title
        stagedEdits.content = content

        CoreDataManager.shared.saveContext()
    }

    func handleAutosaveAction(title: String, content: String) {
        handleStageChangesAction(title: title, content: content)

        // TODO: check for changes. If no changes bail.

        if stagedEdits.postListItem == nil {
            // This is our first remote autosave, so create a new draft post.
            createDraft()
        } else {
            autosave()
        }
    }

    func createDraft() {
        let title = stagedEdits.title ?? ""
        let content = stagedEdits.content ?? ""
        let postService = ApiService.shared.postServiceRemote()

        let params = [
            "title": title,
            "content" : content
        ] as [String: AnyObject]
        draftUUID = UUID()
        postService.createPost(uuid: draftUUID!, postParams: params)
    }

    func autosave() {
        guard let postID = stagedEdits.postListItem?.postID else {
            return
        }

        let title = stagedEdits.title ?? ""
        let content = stagedEdits.content ?? ""
        let postService = ApiService.shared.postServiceRemote()
        postService.autosave(postID: postID, title: title, content: content)
    }

}

// MARK: - Api action handlers
extension EditCoordinator {
    func handleAutosaveApiAction(action: AutosaveApiAction) {

    }

    func handlePostCreatedApiAction(action: PostCreatedApiAction) {

    }

    func handlePostUpdatedApiAction(action: PostUpdatedApiAction) {

    }
}

extension EditCoordinator: GutenbergBridgeDataSource {
    func gutenbergInitialContent() -> String? {
        if
            let edits = postItem?.stagedEdits,
            let content = edits.content
        {
            return content
        }
        return postItem?.post?.content ?? ""
    }

    func gutenbergInitialTitle() -> String? {
        if
            let edits = postItem?.stagedEdits,
            let title = edits.title
        {
            return title
        }
        return postItem?.post?.title ?? ""
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
