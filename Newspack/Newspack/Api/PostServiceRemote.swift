import Foundation

/// Posts endpoint wrangling
///
class PostServiceRemote: ServiceRemoteCoreRest {

    /// Fetch a default list of posts.
    ///
    /// - Parameter onComplete: Completion handler. Has parameteres for an array of remote posts and an error.
    ///
    func fetchPosts(siteUUID: UUID) {
        let parameters = ["context": "edit"] as [String: AnyObject]
        api.GET("posts", parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in

            let array = response as! [[String: AnyObject]]
            let posts = self.remotePostsFromResponse(response: array)

            self.dispatch(action: PostsFetchedApiAction(payload: posts, error: nil, siteUUID: siteUUID))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: PostsFetchedApiAction(payload: nil, error: error, siteUUID: siteUUID))
        })
    }

    /// Fetch post IDs for the specified page.
    ///
    /// - Parameters:
    ///   - siteUUID: The UUID of the site.
    ///   - page: The page to fetch.
    ///
    func fetchPostIDs(siteUUID: UUID, page: Int) {
        let perPage = 100
        let parameters = [
            "_fields": "id,date,modified",
            "page": page,
            "per_page": perPage
        ] as [String: AnyObject]

        api.GET("posts", parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in

            let array = response as! [[String: AnyObject]]
            let postIDs = self.remotePostIDsFromResponse(response: array)
            self.dispatch(action: PostIDsFetchedApiAction(payload: postIDs,
                                                          error: nil,
                                                          siteUUID: siteUUID,
                                                          count: postIDs.count,
                                                          page: page,
                                                          hasMore: postIDs.count == perPage))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: PostIDsFetchedApiAction(payload: nil,
                                                          error: error,
                                                          siteUUID: siteUUID,
                                                          count: 0,
                                                          page: page,
                                                          hasMore: false))
        })
    }

    /// Fetch the specified post from the specified site
    ///
    /// - Parameters:
    ///   - postID: The ID of the post to fetch
    ///   - siteUUID: The UUID of the site.
    ///
    func fetchPost(postID: Int64, fromSite siteUUID: UUID) {
        let parameters = ["context": "edit"] as [String: AnyObject]
        let path = "posts/\(postID)"
        api.GET(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let post = self.remotePostFromResponse(response: dict)

            self.dispatch(action: PostFetchedApiAction(payload: post, error: nil, siteUUID: siteUUID))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            self.dispatch(action: PostFetchedApiAction(payload: nil, error: error, siteUUID: siteUUID))
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
