import Foundation

/// Users endpoint wrangling
///
class UserServiceRemote: ServiceRemoteCoreRest {

    /// Queries the users/me endpoint to get information about the current account.
    ///
    func fetchMe() {
        let parameters = ["context": "edit"] as [String : AnyObject]

        api.GET("users/me", parameters: parameters, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let user = RemoteUser(dict: dict)

            self.dispatch(action: AccountFetchedApiAction(payload: user, error: nil))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            self.dispatch(action: AccountFetchedApiAction(payload: nil, error: error))
        })
    }
}
