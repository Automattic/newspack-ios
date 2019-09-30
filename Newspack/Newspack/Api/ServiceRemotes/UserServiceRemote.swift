import Foundation

/// Users endpoint wrangling
///
class UserServiceRemote: ServiceRemoteCoreRest {

    /// Queries the users/me endpoint to get information about the current account.
    ///
    func fetchMe(_ onComplete: @escaping (_ user: RemoteUser?, _ error: Error?) -> Void) {
        let parameters = ["context": "edit"] as [String : AnyObject]

        api.GET("users/me", parameters: parameters, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let user = RemoteUser(dict: dict)

            onComplete(user, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            onComplete(nil, error)
        })
    }
}
