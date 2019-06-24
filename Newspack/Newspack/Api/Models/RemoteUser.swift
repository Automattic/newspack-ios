import Foundation

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

    /// Convenience initializer to create an instance from a dictionary
    /// Some fields may be empty depending on if the query context was "view" (the default) or "edit".
    ///
    /// - Parameter dict: The source dictionary
    ///
    init(dict: [String: AnyObject]) {
        id = dict[intForKey: "id"]
        username = dict[stringForKey: "username"]
        name = dict[stringForKey: "name"]
        firstName = dict[stringForKey: "first_name"]
        lastName = dict[stringForKey: "last_name"]
        email = dict[stringForKey: "email"]
        url = dict[stringForKey: "url"]
        description = dict[stringForKey: "description"]
        link = dict[stringForKey: "link"]
        locale = dict[stringForKey: "locale"]
        nickname = dict[stringForKey: "nickname"]
        slug = dict[stringForKey: "slug"]
        roles = dict["roles"] as? [String] ?? [String]()
        registeredDate = dict[stringForKey: "registered_date"]
        capabilities = dict["capabilities"] as? [String: Bool] ?? [String: Bool]()
        extraCapabilities = dict["extra_capabilities"] as? [String: String] ?? [String: String]()
        avatarUrls = dict["avatar_urls"] as? [String: String] ?? [String: String]()
    }
}
