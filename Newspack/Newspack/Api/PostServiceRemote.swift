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
            let post = RemotePost(dict: dict)

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
            posts.append(RemotePost(dict: dict))
        }
        return posts
    }

}
