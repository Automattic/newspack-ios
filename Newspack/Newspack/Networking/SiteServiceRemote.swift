import Foundation

/// Sites endpoint wrangling
///
class SiteServiceRemote: ServiceRemoteCoreRest {

    /// Description
    ///
    /// - Parameters:
    ///   - success: success description
    ///   - failure: failure description
    ///
    func fetchSiteSettings(success: @escaping ((RemoteSiteSettings) -> Void), failure: @escaping ((NSError) -> Void)) {
        api.GET("settings", parameters: nil, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let settings = RemoteSiteSettings(dict: dict)
            success(settings)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            failure(error)
        })
    }

}

/// Remote site settings
///
struct RemoteSiteSettings {
    let title: String
    let description: String
    let timezone: String
    let dateFormat: String
    let timeFormat: String
    let startOfWeek: String
    let language: String
    let useSmilies: Bool
    let defaultCategory: Int
    let defaultPostFormat: Int
    let postsPerPage: Int
    let defaultPingStatus: String
    let defaultCommentStatus: String

    /// Convenience initializer to transform a dictionary into an instance of RemoteSiteSettingsV2
    ///
    /// - Parameter dict: The source dictionary
    /// - Returns: An instance of RemoteSiteSettings initialized from the supplied dictionary.
    ///
    init(dict: [String: AnyObject]) {
        title = dict["title"] as? String ?? ""
        description = dict["description"] as? String ?? ""
        timezone = dict["timezone"] as? String ?? ""
        dateFormat = dict["date_format"] as? String ?? ""
        timeFormat = dict["time_format"] as? String ?? ""
        startOfWeek = dict["start_of_week"] as? String ?? ""
        language = dict["language"] as? String ?? ""
        useSmilies = dict["use_smilies"] as? Bool ?? false
        defaultCategory = dict["default_category"] as? Int ?? 0
        defaultPostFormat = dict["default_post_format"] as? Int ?? 0
        postsPerPage = dict["posts_per_page"] as? Int ?? 0
        defaultPingStatus = dict["default_ping_status"] as? String ?? ""
        defaultCommentStatus = dict["default_comment_status"] as? String ?? ""
    }
}
