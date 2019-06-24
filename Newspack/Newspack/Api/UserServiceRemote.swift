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
    func fetchMe() {
        let parameters = ["context": "edit"] as [String : AnyObject]
        api.GET("users/me", parameters: parameters, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let user = RemoteUser(dict: dict)
            self.dispach(action: UserApiAction.accountFetched(user: user, error: nil))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            self.dispach(action: UserApiAction.accountFetched(user: nil, error: error))
        })
    }

}
