import Foundation

/// Posts endpoint wrangling
///
class PostServiceRemote: ServiceRemoteCoreRest {

    /// Fetch post IDs for the specified page.
    ///
    /// - Parameters:
    ///   - filter: A dictionary that identifies a subset of ids to fetch.
    ///   - page: The page to fetch.
    ///   - perPage: The number of items per page.
    ///
    func fetchPostIDs(filter:[String: AnyObject], page: Int, perPage: Int = 100) {
        let params = [
            "_fields": "id,date_gmt,modified_gmt,_links",
            "page": page,
            "per_page": perPage
        ] as [String: AnyObject]
        let parameters = params.mergedWith(filter)

        api.GET("posts", parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let array = response as! [[String: AnyObject]]
            let postIDs = self.remotePostIDsFromResponse(response: array)

            self.dispatch(action: PostIDsFetchedApiAction(payload: postIDs,
                                                          error: nil,
                                                          count: postIDs.count,
                                                          filter: filter,
                                                          page: page,
                                                          hasMore: postIDs.count == perPage))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            // TODO: Need to update WordPressComRestApi to detect code = `rest_post_invalid_page_number` for an http 400 error.
            // For now, assume the error is due to inalid page and go ahead and set hasMore to false.
            self.dispatch(action: PostIDsFetchedApiAction(payload: nil,
                                                          error: error,
                                                          count: 0,
                                                          filter: filter,
                                                          page: page,
                                                          hasMore: false))
        })
    }

    /// Fetch the specified post from the specified site
    ///
    /// - Parameters:
    ///   - postID: The ID of the post to fetch.
    ///
    func fetchPost(postID: Int64) {
        let parameters = ["context": "edit"] as [String: AnyObject]
        let path = "posts/\(postID)"

        api.GET(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let post = self.remotePostFromResponse(response: dict)

            self.dispatch(action: PostFetchedApiAction(payload: post, error: nil, postID: postID))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: PostFetchedApiAction(payload: nil, error: error, postID: postID))
        })
    }

    /// Create or update an autosave for changes to the specified post.
    /// The behavior of this call changes depending on the post's status.
    /// When the post's status is publish, private, or future, the endpoint
    /// will return an autosave revision response.
    /// When the post's status is draft or pending the endpoint returns an empty
    /// array and the changes are applied directly to the draft/pending without
    /// creating a new revision.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post being modified..
    ///   - title: The post's title
    ///   - content: The post's html content.
    ///   - excerpt: An excerpt of the post's content. (Optional.)
    ///
    func autosave(postID: Int64, title: String, content: String, excerpt: String = "") {
        let parameters = [
            "context": "edit",
            "title": title,
            "content": content,
            "excerpt": excerpt
            ] as [String: AnyObject]
        let path = "posts/\(postID)/autosaves"

        api.POST(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            var revision: RemoteRevision?
            if let dict = response as? [String: AnyObject] {
                revision = RemoteRevision(dict: dict)
            }
            self.dispatch(action: AutosaveApiAction(payload: revision, error: nil, postID: postID))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: AutosaveApiAction(payload: nil,
                                                    error: error,
                                                    postID: postID))
        })
    }

    /// Creates a new post with the provided parameters.
    ///
    /// - Parameter postParams: A dictionary having the keys/values with which to create the new post.
    ///
    func createPost(uuid: UUID, postParams: [String: AnyObject]) {
        let defaultParams = [
            "context": "edit"
            ] as [String: AnyObject]

        let parameters = defaultParams.mergedWith(postParams)
        let path = "posts"

        api.POST(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let post = self.remotePostFromResponse(response: dict)

            self.dispatch(action: PostCreatedApiAction(payload: post, error: nil, uuid: uuid))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: PostCreatedApiAction(payload: nil, error: error, uuid: uuid))
        })
    }

    /// Update the specified post with the provided parameters.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post to update.
    ///   - postParams: A dictionary having the keys/values with which to update the specified post.
    ///
    func updatePost(postID: Int64, postParams: [String: AnyObject]) {
        let defaultParams = [
            "context": "edit"
        ] as [String: AnyObject]
        let parameters = defaultParams.mergedWith(postParams)

        let path = "posts/\(postID)"

        api.POST(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let post = self.remotePostFromResponse(response: dict)

            self.dispatch(action: PostUpdatedApiAction(payload: post, error: nil, postID: postID))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: PostUpdatedApiAction(payload: nil, error: error, postID: postID))
        })
    }

}

// MARK: - Remote model management.
//
extension PostServiceRemote {

    /// Format a posts endpoint response into an array of remote posts.
    ///
    /// - Parameter response: The response from an endpoint.
    /// - Returns: An array of RemotePost objects.
    ///
    func remotePostsFromResponse(response: [[String: AnyObject]]) -> [RemotePost] {
        var posts = [RemotePost]()
        for dict in response {
            posts.append(remotePostFromResponse(response: dict))
        }
        return posts
    }

    /// Formats the response from fetching posts with fields limited to identifying information.
    ///
    /// - Parameter response: The response from the posts endpoint
    /// - Returns: An array of RemotePostID objects.
    ///
    func remotePostIDsFromResponse(response: [[String: AnyObject]]) -> [RemotePostID] {
        var postIDs = [RemotePostID]()
        for dict in response {
            postIDs.append(RemotePostID(dict: dict))
        }
        return postIDs
    }

    /// Formats a remote post from an api response.
    ///
    /// - Parameter response: The API response for a post object
    /// - Returns: A RemotePost instance
    ///
    func remotePostFromResponse(response: [String: AnyObject]) -> RemotePost {
        return RemotePost(dict: response)
    }
}
