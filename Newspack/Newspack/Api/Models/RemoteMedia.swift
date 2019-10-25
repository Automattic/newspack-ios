import Foundation

/// Remote representation of a post object.
///
struct RemoteMedia {
    let mediaID: Int64

    let altText: String
    let authorID: Int64
    let caption: String
    let captionRendered: String
    let commentStatus: String
    let date: String
    let dateGMT: Date
    let descript: String
    let descriptionRendered: String
    let generatedSlug: String
    let guid: String
    let guidRendered: String
    let link: String
    let mediaType: String
    let mediaDetails: [String: AnyObject]
    let mimeType: String
    let modified: String
    let modifiedGMT: Date
    let permalinkTemplate: String
    let pingStatus: String
    let postID: Int64
    let slug: String
    let sourceURL: String
    let status: String
    let template: String
    let title: String
    let titleRendered: String
    let type: String

    /// Convenience initializer to create an instance from a dictionary.
    ///
    /// - Parameter dict: The source dictionary
    ///
    init(dict: [String: AnyObject]) {
        mediaID = dict[intForKey: "id"]
        altText = dict[stringForKey: "alt_text"]
        authorID = dict[intForKey: "author"]
        caption = dict[stringAtKeyPath: "caption.raw"]
        captionRendered = dict[stringAtKeyPath: "caption.rendered"]
        commentStatus = dict[stringForKey: "comment_status"]
        date = dict[stringForKey: "date"]
        dateGMT = Date.dateFromGMTString(string: dict[stringForKey: "date_gmt"])!
        descript = dict[stringAtKeyPath: "description.raw"]
        descriptionRendered = dict[stringAtKeyPath: "description.rendered"]
        generatedSlug = dict[stringForKey: "generated_slug"]
        guid = dict[stringAtKeyPath: "guid.raw"]
        guidRendered = dict[stringAtKeyPath: "guid.rendered"]
        link = dict[stringForKey: "link"]
        mediaDetails = dict["media_details"] as! [String: AnyObject]
        mediaType = dict[stringForKey: "media_type"]
        mimeType = dict[stringForKey: "mime_type"]
        modified = dict[stringForKey: "modified"]
        modifiedGMT = Date.dateFromGMTString(string: dict[stringForKey: "modified_gmt"])!
        permalinkTemplate = dict[stringForKey: "permalink_template"]
        pingStatus = dict[stringForKey: "ping_status"]
        postID = dict[intForKey: "post"]
        slug = dict[stringForKey: "slug"]
        sourceURL = dict[stringForKey: "source_url"]
        status = dict[stringForKey: "status"]
        template = dict[stringForKey: "template"]
        title = dict[stringAtKeyPath: "title.raw"]
        titleRendered = dict[stringAtKeyPath: "title.rendered"]
        type = dict[stringForKey: "type"]
    }
}

/// Represent idntifying information about a post.
///
struct RemoteMediaItem {
    let mediaID: Int64
    let dateGMT: Date
    let mediaDetails: [String: AnyObject]
    let mimeType: String
    let modifiedGMT: Date
    let sourceURL: String

    init(dict: [String: AnyObject]) {
        mediaID = dict[intForKey: "id"]
        dateGMT = Date.dateFromGMTString(string: dict[stringForKey: "date_gmt"])!
        mediaDetails = dict["media_details"] as! [String: AnyObject]
        mimeType = dict[stringForKey: "mime_type"]
        modifiedGMT = Date.dateFromGMTString(string: dict[stringForKey: "modified_gmt"])!
        sourceURL = dict[stringForKey: "source_url"]
    }

}
