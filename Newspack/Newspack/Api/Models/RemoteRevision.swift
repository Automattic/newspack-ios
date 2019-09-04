import Foundation

struct RemoteRevision {
    let revisionID: Int64
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
        // The core rest api's posts/ID/autosave endpoint can return null for date and date_gmt
        // if the post is a draft and a date/date_gmt has not previously been set.
        // In these cases, if you check the result of the /posts/ID endpoint result
        // you should see that the value of date/date_gmt matches the value of
        // modified/modified_gmt.  Based on this we'll use the modified/modified_gmt
        // values for date/date_gmt whenever date/date_gmt is null.
        let dateModifiedStr = dict[stringForKey: "modified"]
        let dateModifiedGMT = Date.dateFromGMTString(string: dict[stringForKey: "modified_gmt"])!
        let dateStr = dict[stringForKey: "date"]
        let maybeDateGMT = Date.dateFromGMTString(string: dict[stringForKey: "date_gmt"])

        revisionID = dict[intForKey: "id"]
        authorID = dict[intForKey: "author"]
        content = dict[stringAtKeyPath: "content.raw"]
        contentRendered = dict[stringAtKeyPath: "content.rendered"]

        if let d = maybeDateGMT {
            date = dateStr
            dateGMT = d
        } else {
            date = dateModifiedStr
            dateGMT = dateModifiedGMT
        }

        excerpt = dict[stringAtKeyPath: "excerpt.raw"]
        excerptRendered = dict[stringAtKeyPath: "excerpt.rendered"]
        guid = dict[stringAtKeyPath: "guid.raw"]
        guidRendered = dict[stringAtKeyPath: "guid.rendered"]
        parentID = dict[intForKey: "parent"]
        previewLink = dict[stringForKey: "preview_link"]
        modified = dateModifiedStr
        modifiedGMT = dateModifiedGMT
        slug = dict[stringForKey: "slug"]
        title = dict[stringAtKeyPath: "title.raw"]
        titleRendered = dict[stringAtKeyPath: "title.rendered"]
    }
}
