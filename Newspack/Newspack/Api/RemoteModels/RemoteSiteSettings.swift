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
    let defaultCategory: Int64
    let defaultPostFormat: Int64
    let postsPerPage: Int64
    let defaultPingStatus: String
    let defaultCommentStatus: String

    /// Convenience initializer to create an instance from a dictionary
    ///
    /// - Parameter dict: The source dictionary
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
        defaultCategory = dict["default_category"] as? Int64 ?? 0
        defaultPostFormat = dict["default_post_format"] as? Int64 ?? 0
        postsPerPage = dict["posts_per_page"] as? Int64 ?? 0
        defaultPingStatus = dict["default_ping_status"] as? String ?? ""
        defaultCommentStatus = dict["default_comment_status"] as? String ?? ""
    }
}
