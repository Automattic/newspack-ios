import Foundation
import WordPressFlux

class PostApiService: ApiService {

    let remote: PostServiceRemote

    deinit {
        LogDebug(message: "PostApiService deinit")
    }

    override init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        remote = PostServiceRemote(wordPressComRestApi: api)
        super.init(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    func fetchPostIDs(filter:[String: AnyObject], page: Int, perPage: Int = 100) {
        remote.fetchPostIDs(filter: filter, page: page, perPage: perPage) { (postIDs, error) in

            guard let postIDs = postIDs else {
                // TODO: Need to update WordPressComRestApi to detect code = `rest_post_invalid_page_number` for an http 400 error.
                // For now, assume the error is due to inalid page and go ahead and set hasMore to false.
                self.dispatch(action: PostIDsFetchedApiAction(payload: nil,
                                                              error: error,
                                                              count: 0,
                                                              filter: filter,
                                                              page: page,
                                                              hasMore: false))
                return
            }

            self.dispatch(action: PostIDsFetchedApiAction(payload: postIDs,
                                                          error: nil,
                                                          count: postIDs.count,
                                                          filter: filter,
                                                          page: page,
                                                          hasMore: postIDs.count == perPage))
        }
    }

    func fetchPost(postID: Int64) {
        remote.fetchPost(postID: postID) { (post, error) in
            self.dispatch(action: PostFetchedApiAction(payload: post, error: error, postID: postID))
        }
    }

    func autosave(postID: Int64, title: String, content: String, excerpt: String = "") {
        remote.autosave(postID: postID, title: title, content: content, excerpt: excerpt) { (revision, error) in
            self.dispatch(action: AutosaveApiAction(payload: revision, error: error, postID: postID))
        }
    }

    func createPost(uuid: UUID, postParams: [String: AnyObject]) {
        remote.createPost(postParams: postParams) { (post, error) in
            self.dispatch(action: PostCreatedApiAction(payload: post, error: error, uuid: uuid))
        }
    }

    func updatePost(postID: Int64, postParams: [String: AnyObject]) {
        remote.updatePost(postID: postID, postParams: postParams) { (post, error) in
            self.dispatch(action: PostUpdatedApiAction(payload: post, error: error, postID: postID))
        }
    }
}
