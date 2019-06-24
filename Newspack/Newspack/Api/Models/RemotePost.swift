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
        postID = dict["id"] as? Int64 ?? 0
        authorID = dict["author"] as? Int64 ?? 0
        categories = dict["categories"] as? [Int64] ?? [Int64]()
        commentStatus = dict["comment_status"] as? String ?? ""
        content = dict[keyPath: "content.raw"] as? String ?? ""
        contentRendered = dict[keyPath: "content.rendered"] as? String ?? ""
        date = dict["date"] as? String ?? ""
        dateGMT = dict["date_gmt"] as? String ?? ""
        excerpt = dict[keyPath: "excerpt.raw"] as? String ?? ""
        excerptRendered = dict[keyPath: "excerpt.rendered"] as? String ?? ""
        featuredMedia = dict["featured_media"] as? Int64 ?? 0
        format = dict["format"] as? String ?? ""
        generatedSlug = dict["generated_slug"] as? String ?? ""
        guid = dict[keyPath: "guid.raw"] as? String ?? ""
        guidRendered = dict[keyPath: "guid.rendered"] as? String ?? ""
        link = dict["link"] as? String ?? ""
        modified = dict["modified"] as? String ?? ""
        modifiedGMT = dict["modified_gmt"] as? String ?? ""
        password = dict["password"] as? String ?? ""
        permalinkTemplate = dict["permalink_template"] as? String ?? ""
        pingStatus = dict["ping_status"] as? String ?? ""
        slug = dict["slug"] as? String ?? ""
        status = dict["status"] as? String ?? ""
        sticky = dict["sticky"] as? Bool ?? false
        tags = dict["tags"] as? [Int64] ?? [Int64]()
        template = dict["template"] as? String ?? ""
        title = dict[keyPath: "title.raw"] as? String ?? ""
        titleRendered = dict[keyPath: "title.rendered"] as? String ?? ""
        type = dict["type"] as? String ?? ""
    }
}
