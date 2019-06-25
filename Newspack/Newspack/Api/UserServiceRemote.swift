import Foundation

/// Users endpoint wrangling
///
class UserServiceRemote: ServiceRemoteCoreRest {

    /// Queries the users/me endpoint to get information about the current account.
    ///
    /// - Parameters:
    ///   - accountUUID: The UUID of the account, for details.
    ///   - siteUUID: The UUID of the site, for capabilities.
    ///
    func fetchMe(accountUUID: UUID, siteUUID: UUID) {
        let parameters = ["context": "edit"] as [String : AnyObject]
        api.GET("users/me", parameters: parameters, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let user = RemoteUser(dict: dict)

            self.dispatch(action: AccountFetchedApiAction(payload: user, error: nil, accountUUID: accountUUID, siteUUID: siteUUID))

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            self.dispatch(action: AccountFetchedApiAction(payload: nil, error: error, accountUUID: accountUUID, siteUUID: siteUUID))
        })
    }

}
