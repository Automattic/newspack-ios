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
    func fetchSiteSettings(success: @escaping ((RemoteSiteSettingsV2) -> Void), failure: @escaping ((NSError) -> Void)) {
        api.GET("settings", parameters: nil, success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) in

            let dict = response as! [String: AnyObject]
            let settings = RemoteSiteSettingsV2.fromDictionary(dict: dict)
            success(settings)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
            failure(error)
        })
    }

}

/// Remote site settings
///
struct RemoteSiteSettingsV2 {
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

    /// Convenience factory to transform a dictionary into an instance of RemoteSiteSettingsV2
    ///
    /// - Parameter dict: The source dictionary
    /// - Returns: An instance of RemoteSiteSettingsV2 initialized from the supplied dictionary.
    ///
    static func fromDictionary(dict: [String: AnyObject]) -> RemoteSiteSettingsV2 {
        let title: String = dict["title"] as? String ?? ""
        let description: String = dict["description"] as? String ?? ""
        let timezone: String = dict["timezone"] as? String ?? ""
        let dateFormat: String = dict["date_format"] as? String ?? ""
        let timeFormat: String = dict["time_format"] as? String ?? ""
        let startOfWeek: String = dict["start_of_week"] as? String ?? ""
        let language: String = dict["language"] as? String ?? ""
        let useSmilies: Bool = dict["use_smilies"] as? Bool ?? false
        let defaultCategory: Int = dict["default_category"] as? Int ?? 0
        let defaultPostFormat: Int = dict["default_post_format"] as? Int ?? 0
        let postsPerPage: Int = dict["posts_per_page"] as? Int ?? 0
        let defaultPingStatus: String = dict["default_ping_status"] as? String ?? ""
        let defaultCommentStatus: String = dict["default_comment_status"] as? String ?? ""

        return RemoteSiteSettingsV2(title: title,
                                    description: description,
                                    timezone: timezone,
                                    dateFormat: dateFormat,
                                    timeFormat: timeFormat,
                                    startOfWeek: startOfWeek,
                                    language: language,
                                    useSmilies: useSmilies,
                                    defaultCategory: defaultCategory,
                                    defaultPostFormat: defaultPostFormat,
                                    postsPerPage: postsPerPage,
                                    defaultPingStatus: defaultPingStatus,
                                    defaultCommentStatus: defaultCommentStatus)
    }
}
