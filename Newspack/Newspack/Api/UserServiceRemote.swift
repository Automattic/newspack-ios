import Foundation

/// Users endpoint wrangling
///
class UserServiceRemote: ServiceRemoteCoreRest {

    /// Queries the users/me endpoint to get information about the current account.
    ///
    /// - Parameters:
    ///   - success: success description
    ///   - failure: failure description
    ///
    func fetchMe(success: @escaping ((RemoteUser) -> Void), failure: @escaping ((NSError) -> Void)) {
        let parameters = ["context": "edit"] as [String : AnyObject]
        api.GET("users/me", parameters: parameters, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let user = RemoteUser(dict: dict)
            success(user)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            failure(error)
        })
    }

}
