import Foundation

/// Posts endpoint wrangling
///
class PostServiceRemote: ServiceRemoteCoreRest {

    /// Fetch post stubs for the specified IDs.
    ///
    /// - Parameters:
    ///   - postIDs: A list of post IDs to fetch.
    ///   - page: The page to fetch. Default is 1.
    ///   - perPage: The number of items per page. Default is 100.
    ///   - onComplete: A completion block.
    ///
    func fetchPostStubs(for postIDs: [Int64],
                        page: Int,
                        perPage: Int,
                        onComplete: @escaping (_ postIDs: [RemotePostStub]?, _ error: Error?) -> Void) {
        let ids = postIDs.map { (item) -> String in
            String(item)
        }.joined(separator: ",")

        let filter = ["id": ids] as [String: AnyObject]
        let params = [
            "_fields": "id,title,status,date_gmt,modified_gmt,_links",
            "status": "draft,pending",
            "page": page,
            "per_page": perPage
        ] as [String: AnyObject]
        let parameters = params.mergedWith(filter)

        api.GET("posts", parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            guard let array = response as? [[String: AnyObject]] else {
                onComplete(nil, ApiError.unexpectedDataFormat)
                return
            }

            let posts = self.remotePostStubsFromResponse(response: array)

            onComplete(posts, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
        })
    }

    /// Creates a new post with the provided parameters.
    ///
    /// - Parameter postParams: A dictionary having the keys/values with which to create the new post.
    ///
    func createPost(postParams: [String: AnyObject], onComplete: @escaping (_ post: RemotePost?, _ error: Error?) -> Void) {
        let defaultParams = [
            "context": "edit"
            ] as [String: AnyObject]

        let parameters = defaultParams.mergedWith(postParams)
        let path = "posts"

        api.POST(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let post = self.remotePostFromResponse(response: dict)

            onComplete(post, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
        })
    }

    /// Update the specified post with the provided parameters.
    ///
    /// - Parameters:
    ///   - postID: The ID of the post to update.
    ///   - postParams: A dictionary having the keys/values with which to update the specified post.
    ///
    func updatePost(postID: Int64, postParams: [String: AnyObject], onComplete: @escaping (_ post: RemotePost?, _ error: Error?) -> Void) {
        let defaultParams = [
            "context": "edit"
        ] as [String: AnyObject]
        let parameters = defaultParams.mergedWith(postParams)

        let path = "posts/\(postID)"

        api.POST(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let post = self.remotePostFromResponse(response: dict)

            onComplete(post, nil)

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
            posts.append(remotePostFromResponse(response: dict))
        }
        return posts
    }

    /// Format a posts endpoint response into an array of remote post stubs.
    ///
    /// - Parameter response: The response from an endpoint.
    /// - Returns: An array of RemotePostStub objects.
    ///
    func remotePostStubsFromResponse(response: [[String: AnyObject]]) -> [RemotePostStub] {
        var posts = [RemotePostStub]()
        for dict in response {
            posts.append(RemotePostStub(dict: dict))
        }
        return posts
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
