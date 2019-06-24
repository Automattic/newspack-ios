import Foundation

/// Posts endpoint wrangling
///
class PostServiceRemote: ServiceRemoteCoreRest {

    /// Fetch a default list of posts.
    ///
    /// - Parameter onComplete: Completion handler. Has parameteres for an array of remote posts and an error.
    ///
    func fetchPosts(onComplete: @escaping (([RemotePost]?, NSError?) ->Void )) {

        api.GET("posts", parameters: nil, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in

            let array = response as! [[String: AnyObject]]
            let posts = self.remotePostsFromResponse(response: array)

            onComplete(posts, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
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
