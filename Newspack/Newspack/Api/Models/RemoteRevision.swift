import Foundation

struct RemoteRevision {
    let postID: Int64
    let authorID: Int64
    let content: String
    let contentRendered: String
    let date: String
    let dateGMT: Date
    let excerpt: String
    let excerptRendered: String
    let guid: String
    let guidRendered: String
    let modified: String
    let modifiedGMT: Date
    let parentID: Int64
    let previewLink: String // Only for results from autosave endpoint.
    let slug: String
    let title: String
    let titleRendered: String

    /// Convenience initializer to create an instance from a dictionary.
    ///
    /// - Parameter dict: The source dictionary
    ///
    init(dict: [String: AnyObject]) {
        postID = dict[intForKey: "id"]
        authorID = dict[intForKey: "author"]
        content = dict[stringAtKeyPath: "content.raw"]
        contentRendered = dict[stringAtKeyPath: "content.rendered"]
        date = dict[stringForKey: "date"]
        dateGMT = Date.dateFromGMTString(string: dict[stringForKey: "date_gmt"])!
        excerpt = dict[stringAtKeyPath: "excerpt.raw"]
        excerptRendered = dict[stringAtKeyPath: "excerpt.rendered"]
        guid = dict[stringAtKeyPath: "guid.raw"]
        guidRendered = dict[stringAtKeyPath: "guid.rendered"]
        parentID = dict[intForKey: "parent"]
        previewLink = dict[stringForKey: "preview_link"]
        modified = dict[stringForKey: "modified"]
        modifiedGMT = Date.dateFromGMTString(string: dict[stringForKey: "modified_gmt"])!
        slug = dict[stringForKey: "slug"]
        title = dict[stringAtKeyPath: "title.raw"]
        titleRendered = dict[stringAtKeyPath: "title.rendered"]
    }
}
