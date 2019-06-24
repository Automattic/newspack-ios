import Foundation

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
        title = dict[stringForKey: "title"]
        description = dict[stringForKey: "description"]
        timezone = dict[stringForKey: "timezone"]
        dateFormat = dict[stringForKey: "date_format"]
        timeFormat = dict[stringForKey: "time_format"]
        startOfWeek = dict[stringForKey: "start_of_week"]
        language = dict[stringForKey: "language"]
        useSmilies = dict[boolForKey: "use_smilies"]
        defaultCategory = dict[intForKey: "default_category"]
        defaultPostFormat = dict[intForKey: "default_post_format"]
        postsPerPage = dict[intForKey: "posts_per_page"]
        defaultPingStatus = dict[stringForKey: "default_ping_status"]
        defaultCommentStatus = dict[stringForKey: "default_comment_status"]
    }
}
