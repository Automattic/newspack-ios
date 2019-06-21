import Foundation

/// Users endpoint wrangling
///
class UserServiceRemote: ServiceRemoteCoreRest {

    /// Description
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

/// Remote User
///
struct RemoteUser {
    let id: Int64
    let username: String
    let name: String
    let firstName: String
    let lastName: String
    let email: String
    let url: String
    let description: String
    let link: String
    let locale: String
    let nickname: String
    let slug: String
    let roles: [String]
    let registeredDate: String
    let capabilities: [String: Bool]
    let extraCapabilities: [String: String]
    let avatarUrls: [String: String]

    /// Convenience initializer to transform a dictionary into an instance of RemoteUser
    /// Some fields may be empty depending on if the query context was "view" (the default) or "edit".
    ///
    /// - Parameter dict: The source dictionary
    /// - Returns: An instance of RemoteSiteSettingsV2 initialized from the supplied dictionary.
    ///
    init(dict: [String: AnyObject]) {
        id = dict["id"] as? Int64 ?? 0
        username = dict["username"] as? String ?? ""
        name = dict["name"] as? String ?? ""
        firstName = dict["first_name"] as? String ?? ""
        lastName = dict["last_name"] as? String ?? ""
        email = dict["email"] as? String ?? ""
        url = dict["url"] as? String ?? ""
        description = dict["description"] as? String ?? ""
        link = dict["link"] as? String ?? ""
        locale = dict["locale"] as? String ?? ""
        nickname = dict["nickname"] as? String ?? ""
        slug = dict["slug"] as? String ?? ""
        roles = dict["roles"] as? [String] ?? [String]()
        registeredDate = dict["registered_date"] as? String ?? ""
        capabilities = dict["capabilities"] as? [String: Bool] ?? [String: Bool]()
        extraCapabilities = dict["extra_capabilities"] as? [String: String] ?? [String: String]()
        avatarUrls = dict["avatar_urls"] as? [String: String] ?? [String: String]()
    }
}
