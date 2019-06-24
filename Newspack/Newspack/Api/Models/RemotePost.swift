import Foundation

/// Remote representation of a post object.
///
struct RemotePost {
    let postID: Int64
    let authorID: Int64
    let categories: [Int64]
    let commentStatus: String
    let content: String
    let contentRendered: String
    let date: String
    let dateGMT: String
    let excerpt: String
    let excerptRendered: String
    let featuredMedia: Int64
    let format: String
    let generatedSlug: String
    let guid: String
    let guidRendered: String
    let link: String
    let modified: String
    let modifiedGMT: String
    let password: String
    let permalinkTemplate: String
    let pingStatus: String
    let slug: String
    let status: String
    let sticky: Bool
    let tags: [Int64]
    let template: String
    let title: String
    let titleRendered: String
    let type: String

    /// Convenience initializer to create an instance from a dictionary. 
    ///
    /// - Parameter dict: The source dictionary
    ///
    init(dict: [String: AnyObject]) {
        postID = dict[intForKey: "id"]
        authorID = dict[intForKey: "author"]
        categories = dict["categories"] as? [Int64] ?? [Int64]()
        commentStatus = dict[stringForKey: "comment_status"]
        content = dict[stringAtKeyPath: "content.raw"]
        contentRendered = dict[stringAtKeyPath: "content.rendered"]
        date = dict[stringForKey: "date"]
        dateGMT = dict[stringForKey: "date_gmt"]
        excerpt = dict[stringAtKeyPath: "excerpt.raw"]
        excerptRendered = dict[stringAtKeyPath: "excerpt.rendered"]
        featuredMedia = dict[intForKey: "featured_media"]
        format = dict[stringForKey: "format"]
        generatedSlug = dict[stringForKey: "generated_slug"]
        guid = dict[stringAtKeyPath: "guid.raw"]
        guidRendered = dict[stringAtKeyPath: "guid.rendered"]
        link = dict[stringForKey: "link"]
        modified = dict[stringForKey: "modified"]
        modifiedGMT = dict[stringForKey: "modified_gmt"]
        password = dict[stringForKey: "password"]
        permalinkTemplate = dict[stringForKey: "permalink_template"]
        pingStatus = dict[stringForKey: "ping_status"]
        slug = dict[stringForKey: "slug"]
        status = dict[stringForKey: "status"]
        sticky = dict[boolForKey: "sticky"]
        tags = dict["tags"] as? [Int64] ?? [Int64]()
        template = dict[stringForKey: "template"]
        title = dict[stringAtKeyPath: "title.raw"]
        titleRendered = dict[stringAtKeyPath: "title.rendered"]
        type = dict[stringForKey: "type"]
    }
}
