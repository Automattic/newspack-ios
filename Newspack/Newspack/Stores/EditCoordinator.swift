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
    var createdPostUUID: UUID? // An identifier used to pair an api action to edits being made.

    var hasLocalChanges: Bool {
        if stagedEdits.title == "" && stagedEdits.content == "" {
            return false
        }

        if let post = stagedEdits.postListItem?.post {
            return stagedEdits.title != post.title || stagedEdits.content != post.content
        }

        return true
    }

    init(postItem: PostListItem?, dispatcher: ActionDispatcher, siteID: UUID) {
        self.currentSiteID = siteID
        self.postItem = postItem
        self.stagedEdits = postItem?.stagedEdits ?? StagedEdits(context: CoreDataManager.shared.mainContext)
        super.init(dispatcher: dispatcher)
    }

    override func onDispatch(_ action: Action) {
        // API Actions
        if let apiAction = action as? PostCreatedApiAction {
            handlePostCreatedApiAction(action: apiAction)
            return
        } else if let apiAction = action as? AutosaveApiAction {
            handleAutosaveApiAction(action: apiAction)
            return
        } else if let apiAction = action as? PostUpdatedApiAction {
            handlePostUpdatedApiAction(action: apiAction)
            return
        }

        // Save Actions
        if let saveAction = action as? PostSaveAction {
            handlePostSaveAction(action: saveAction)
            return
        }

        // Edit Actions
        guard let editAction = action as? EditAction else {
            return
        }

        switch editAction {
        case .autosave(let title, let content):
            handleAutosaveAction(title: title, content: content)
        case .stageChanges(let title, let content):
            handleStageChangesAction(title: title, content: content)
        case .discardChanges:
            handleDiscardChangesAction()
        }
    }

}

// MARK: - Edit and Save Action Handlers
extension EditCoordinator {

    func handlePostSaveAction(action: PostSaveAction) {
        switch action {
        case .publish:
            createOrUpdatePostWithStatus(status: "publish")
        case .publishPrivately:
            createOrUpdatePostWithStatus(status: "private")
        case .saveAsDraft:
            createOrUpdatePostWithStatus(status: "draft")
        case .saveAsPending:
            createOrUpdatePostWithStatus(status: "pending")
        case .trash:
            createOrUpdatePostWithStatus(status: "trash")
            break
        }
    }

    func handleStageChangesAction(title: String, content: String) {
        guard
            title != stagedEdits.title || content != stagedEdits.content,
            let context = stagedEdits.managedObjectContext
        else {
            return
        }
        stagedEdits.title = title
        stagedEdits.content = content
        stagedEdits.lastModified = Date()

        // This should be in response to a user action so we will save on the main thread.
        CoreDataManager.shared.saveContext(context: context)
    }

    func handleAutosaveAction(title: String, content: String) {
        handleStageChangesAction(title: title, content: content)

        guard let item = stagedEdits.postListItem else {
            // This is our first remote autosave, so create a new draft post and post list item.
            createPostWithStatus(status: "draft")
            return
        }

        if item.modifiedGMT > stagedEdits.lastModified {
            // No changes.
            return
        }

        autosave()
    }

    func handleDiscardChangesAction() {
        // TODO: This will need also need to clean up a "local" post list item if we go that route.
        let objID = stagedEdits.objectID
        CoreDataManager.shared.performOnWriteContext { (context) in
            let edits = context.object(with: objID) as! StagedEdits
            context.delete(edits)
            CoreDataManager.shared.saveContext(context: context)
        }
    }
}

// MARK: - API Calls
extension EditCoordinator {

    func autosave() {
        guard let postID = stagedEdits.postListItem?.postID else {
            // TODO: Log this
            LogError(message: "autosave: Unable to get post by postID.")
            return
        }

        let title = stagedEdits.title ?? ""
        let content = stagedEdits.content ?? ""
        let service = ApiService.postService()
        service.autosave(postID: postID, title: title, content: content)
    }

    func createOrUpdatePostWithStatus(status: String) {
        guard let post = stagedEdits.postListItem?.post else {
            createPostWithStatus(status: status)
            return
        }
        updatePost(post: post, withStatus: status)
    }

    func createPostWithStatus(status: String) {
        let service = ApiService.postService()

        let title = stagedEdits.title ?? ""
        let content = stagedEdits.content ?? ""
        let params = [
            "title": title,
            "content" : content,
            "status" : status,
            ] as [String: AnyObject]
        createdPostUUID = UUID()
        service.createPost(uuid: createdPostUUID!, postParams: params)
    }

    func updatePost(post: Post, withStatus status: String) {
        var params = parametersFromPost(post: post)
        params["status"] = status as AnyObject

        let service = ApiService.postService()
        service.updatePost(postID: post.postID, postParams: params)
    }

    func parametersFromPost(post: Post) -> [String: AnyObject] {
        var dict = [String: Any]()
        // TODO: Flesh this out as other properties are editable.
        if let stagedEdits = post.item.stagedEdits {
            dict["title"] = stagedEdits.title
            dict["content"] = stagedEdits.content
        } else {
            dict["title"] = post.title
            dict["content"] = post.content
        }
        dict["date"] = post.date
        return dict as [String: AnyObject]
    }
}

// MARK: - API action handlers
extension EditCoordinator {

    func handleAutosaveApiAction(action: AutosaveApiAction) {
        if action.isError() {
            // TODO: Handle error
            if let error = action.error as NSError? {
                LogError(message: "handleAutosaveApiAction: " + error.localizedDescription)
            }
            return
        }

        guard
            let remoteRevision = action.payload,
            let post = stagedEdits.postListItem?.post
        else {
            // This is a critical error and should not be able to happen.
            LogError(message: "handleAutosaveApiAction: Critical Error. A value was unexpectedly nil.")
            return
        }

        if remoteRevision.parentID == 0 {
            // we're updating a draft/pending post directly.
            updateAndSavePost(post: post, with: remoteRevision)

        } else if remoteRevision.parentID == post.postID {
            // we're updating an autosave on published/scheduled/private post.
            createOrUpdateAutosaveRevisionForPost(post: post, with: remoteRevision)
        } else {
            // TODO: Handle error.
            LogError(message: "handleAutosaveApiAction: Critical Error. Unable to create or update post.")
            assertionFailure()
        }
    }

    func updateAndSavePost(post: Post, with remoteRevision: RemoteRevision) {
        guard post.postID == remoteRevision.revisionID else {
            LogError(message: "updatePost: Post ID did not match Revision ID.")
            return
        }

        let postObjID = post.objectID
        CoreDataManager.shared.performOnWriteContext { (context) in
            let post = context.object(with: postObjID) as! Post

            // Update a draft/pending post with remote post.
            // Autosaves should only update title, content, exerpt and modified.
            // However, update the date also in case it should match date modified.
            post.title = remoteRevision.title
            post.titleRendered = remoteRevision.titleRendered
            post.content = remoteRevision.content
            post.contentRendered = remoteRevision.contentRendered
            post.excerpt = remoteRevision.excerpt
            post.excerptRendered = remoteRevision.excerptRendered
            post.date = remoteRevision.date
            post.dateGMT = remoteRevision.dateGMT
            post.modified = remoteRevision.modified
            post.modifiedGMT = remoteRevision.modifiedGMT

            // Enusre the post list item reflects the updated date.
            post.item.dateGMT = post.dateGMT
            post.item.modifiedGMT = post.modifiedGMT

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    func createOrUpdateAutosaveRevisionForPost(post: Post, with remoteRevision: RemoteRevision) {
        // create or update autosave revision
        let objID = post.objectID
        CoreDataManager.shared.performOnWriteContext { [weak self] (context) in
            let post = context.object(with: objID) as! Post
            let fetchRequest = Revision.defaultFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "post == %@ AND revisionID == %ld", post, remoteRevision.revisionID)

            let revision: Revision
            do {
                revision = try context.fetch(fetchRequest).first ?? Revision(context: context)
            } catch {
                revision = Revision(context: context)

                let error = error as NSError
                LogError(message: "createOrUpdateAutosaveRevisionForPost: " + error.localizedDescription)
            }

            self?.updateRevision(revision: revision, with: remoteRevision)
            revision.post = post

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    func handlePostCreatedApiAction(action: PostCreatedApiAction) {
        if action.isError() {
            if let error = action.error as NSError? {
                LogError(message: "handlePostCreatedApiAction: " + error.localizedDescription)
            }
            // TODO: handle error
            return
        }

        guard
            let remotePost = action.payload,
            action.uuid == createdPostUUID
        else {
            LogError(message: "handlePostCreatedApiAction: A value was unexpectedly nil, or failed an equality check.")
            return
        }

        createdPostUUID = nil

        // Use the payload to create a new Post and PostListItem.
        // The item should be assigned to the "ALL" PostList.

        guard let listObjID = StoreContainer.shared.postListStore.postListByName(name: "all", siteUUID: currentSiteID)?.objectID else {
            LogError(message: "handlePostCreatedApiAction: A value was unexpectedly nil.")
            return
        }
        let editsID = stagedEdits.objectID

        CoreDataManager.shared.performOnWriteContext { (context) in
            let list = context.object(with: listObjID) as! PostList
            let stagedEdits = context.object(with: editsID) as! StagedEdits

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

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    func handlePostUpdatedApiAction(action: PostUpdatedApiAction) {
        if action.isError() {
            // TODO: Handle error
            if let error = action.error as NSError? {
                LogError(message: "handlePostUpdatedApiAction: " + error.localizedDescription)
            }
            return
        }

        guard
            let remotePost = action.payload,
            let postItem = postItem,
            let post = postItem.post,
            post.postID == remotePost.postID
        else {
            LogError(message: "handlePostCreatedApiAction: A value was unexpectedly nil.")
            return
        }

        let postObjID = post.objectID
        let itemObjID = postItem.objectID
        CoreDataManager.shared.performOnWriteContext { (context) in
            let post = context.object(with: postObjID) as! Post
            let postItem = context.object(with: itemObjID) as! PostListItem

            let postStore = StoreContainer.shared.postStore
            postStore.updatePost(post, with: remotePost)

            // TODO: This work could be moved into postStore.updatePost provided
            // there is always a postItem.
            postItem.dateGMT = post.dateGMT
            postItem.modifiedGMT = post.modifiedGMT
            postItem.revisionCount = post.revisionCount

            CoreDataManager.shared.saveContext(context: context)
        }
    }

    func updateRevision(revision: Revision, with remoteRevision: RemoteRevision) {
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

// MARK: - Gutenberg related
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

// MARK: - UIAlertController related / Save options.
extension EditCoordinator {

    func getSaveAlertController() -> UIAlertController {
        var canUpdate = false
        if let post = postItem?.post {
            canUpdate = postCanUpdate(post: post)
        }
        return EditorSaveAlertControllerFactory().controllerForStagedEdits(stagedEdits: stagedEdits, canUpdate: canUpdate, for: postItem?.post)
    }

    func postCanUpdate(post: Post) -> Bool {
        return stagedEdits.title != post.title || stagedEdits.content != post.content
    }
}
