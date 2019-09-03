import Foundation
import WordPressFlux
import Gutenberg
import Aztec

/// Provides a bridge between the Editor, and the content being edited.
///
class EditCoordinator: Store {

    private let currentSiteID: UUID
    var postItem: PostListItem?
    let stagedEdits: StagedEdits
    var draftUUID: UUID? // An identifier used to pair an api action to edits being made.

    init(postItem: PostListItem?, dispatcher: ActionDispatcher, siteID: UUID) {
        self.currentSiteID = siteID
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
        if action.isError() {
            // TODO:
            return
        }

        guard let remoteRevision = action.payload else {
            // If the payload is empty, the post is either draft or pending and
            // was directly updated by the autosave.
            return
        }

        guard let post = stagedEdits.postListItem?.post else {
            // this shouldn't happen.
            return
        }

        // create or update autosave revision
        let context = CoreDataManager.shared.mainContext
        let fetchRequest = Revision.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "post == %@ AND revisionID == %ld", post, remoteRevision.revisionID)

        let revision: Revision
        do {
            revision = try context.fetch(fetchRequest).first ?? Revision(context: context)
        } catch {
            revision = Revision(context: context)
            // TODO: properly log this
        }

        updateRevision(revision: revision, with: remoteRevision)
        revision.post = post
        CoreDataManager.shared.saveContext()
    }


    func handlePostCreatedApiAction(action: PostCreatedApiAction) {
        if action.isError() {
            // TODO:
            return
        }

        guard
            let remotePost = action.payload,
            action.uuid == draftUUID
        else {
            return
        }

        draftUUID = nil

        // Use the payload to create a new Post and PostListItem.
        // The item should be assigned to the "ALL" PostList.

        guard let list = StoreContainer.shared.postListStore.postListByName(name: "all", siteUUID: currentSiteID) else {
            return
        }

        let context = CoreDataManager.shared.mainContext

        let postStore = StoreContainer.shared.postStore
        let post = Post(context: context)
        postStore.updatePost(post, with: remotePost)
        post.site = list.site

        let postItem = PostListItem(context: context)
        postItem.postID = post.postID
        postItem.dateGMT = post.dateGMT
        postItem.modifiedGMT = post.modifiedGMT
        postItem.revisionCount = 0

        postItem.stagedEdits = stagedEdits
        postItem.post = post
        postItem.site = list.site
        postItem.addToPostLists(list)

    }

    func handlePostUpdatedApiAction(action: PostUpdatedApiAction) {
        // TODO:

    }


    func updateRevision(revision:Revision, with remoteRevision: RemoteRevision) {
        revision.authorID = remoteRevision.authorID
        revision.content = remoteRevision.content
        revision.contentRendered = remoteRevision.contentRendered
        revision.date = remoteRevision.date
        revision.dateGMT = remoteRevision.dateGMT
        revision.excerpt = remoteRevision.excerpt
        revision.excerptRendered = remoteRevision.excerptRendered
        revision.modified = remoteRevision.modified
        revision.modifiedGMT = remoteRevision.modifiedGMT
        revision.parentID = remoteRevision.parentID
        revision.revisionID = remoteRevision.revisionID
        revision.slug = remoteRevision.slug
        revision.title = remoteRevision.title
        revision.titleRendered = remoteRevision.titleRendered
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
