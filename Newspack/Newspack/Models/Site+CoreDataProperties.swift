import Foundation
import CoreData


extension Site {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Site> {
        return NSFetchRequest<Site>(entityName: "Site")
    }

    @NSManaged public var dateFormat: String!
    @NSManaged public var defaultCategory: Int64
    @NSManaged public var defaultCommentStatus: String!
    @NSManaged public var defaultPingStatus: String!
    @NSManaged public var defaultPostFormat: Int64
    @NSManaged public var language: String!
    @NSManaged public var postsPerPage: Int64
    @NSManaged public var siteFolder: Data!
    @NSManaged public var startOfWeek: String!
    @NSManaged public var summary: String!
    @NSManaged public var timeFormat: String!
    @NSManaged public var timezone: String!
    @NSManaged public var title: String!
    @NSManaged public var url: String!
    @NSManaged public var useSmilies: Bool
    @NSManaged public var uuid: UUID!

    @NSManaged public var account: Account!
    @NSManaged public var capabilities: AccountCapabilities?
    @NSManaged public var media: Set<Media>!
    @NSManaged public var mediaItems: Set<MediaItem>!
    @NSManaged public var mediaQueries: Set<MediaQuery>!
    @NSManaged public var pages: Set<Page>!
    @NSManaged public var postItems: Set<PostItem>!
    @NSManaged public var postQueries: Set<PostQuery>!
    @NSManaged public var posts: Set<Post>!
    @NSManaged public var stagedMedia: Set<Status>!
    @NSManaged public var statuses: Set<Status>!
    @NSManaged public var storyFolders: Set<Status>!
    @NSManaged public var users: Set<User>!

}

// MARK: Generated accessors for media
extension Site {

    @objc(addMediaObject:)
    @NSManaged public func addToMedia(_ value: Media)

    @objc(removeMediaObject:)
    @NSManaged public func removeFromMedia(_ value: Media)

    @objc(addMedia:)
    @NSManaged public func addToMedia(_ values: Set<Media>)

    @objc(removeMedia:)
    @NSManaged public func removeFromMedia(_ values: Set<Media>)

}

// MARK: Generated accessors for mediaItems
extension Site {

    @objc(addMediaItemsObject:)
    @NSManaged public func addToMediaItems(_ value: MediaItem)

    @objc(removeMediaItemsObject:)
    @NSManaged public func removeFromMediaItems(_ value: MediaItem)

    @objc(addMediaItems:)
    @NSManaged public func addToMediaItems(_ values: Set<MediaItem>)

    @objc(removeMediaItems:)
    @NSManaged public func removeFromMediaItems(_ values: Set<MediaItem>)

}

// MARK: Generated accessors for mediaQueries
extension Site {

    @objc(addMediaQueriesObject:)
    @NSManaged public func addToMediaQueries(_ value: MediaQuery)

    @objc(removeMediaQueriesObject:)
    @NSManaged public func removeFromMediaQueries(_ value: MediaQuery)

    @objc(addMediaQueries:)
    @NSManaged public func addToMediaQueries(_ values: Set<MediaQuery>)

    @objc(removeMediaQueries:)
    @NSManaged public func removeFromMediaQueries(_ values: Set<MediaQuery>)

}

// MARK: Generated accessors for pages
extension Site {

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: Page)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: Page)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: Set<Page>)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: Set<Page>)

}

// MARK: Generated accessors for postItems
extension Site {

    @objc(addPostItemsObject:)
    @NSManaged public func addToPostItems(_ value: PostItem)

    @objc(removePostItemsObject:)
    @NSManaged public func removeFromPostItems(_ value: PostItem)

    @objc(addPostItems:)
    @NSManaged public func addToPostItems(_ values: Set<PostItem>)

    @objc(removePostItems:)
    @NSManaged public func removeFromPostItems(_ values: Set<PostItem>)

}

// MARK: Generated accessors for postQueries
extension Site {

    @objc(addPostQueriesObject:)
    @NSManaged public func addToPostQueries(_ value: PostQuery)

    @objc(removePostQueriesObject:)
    @NSManaged public func removeFromPostQueries(_ value: PostQuery)

    @objc(addPostQueries:)
    @NSManaged public func addToPostQueries(_ values: Set<PostQuery>)

    @objc(removePostQueries:)
    @NSManaged public func removeFromPostQueries(_ values: Set<PostQuery>)

}

// MARK: Generated accessors for posts
extension Site {

    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: Post)

    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: Post)

    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: Set<Post>)

    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: Set<Post>)

}

// MARK: Generated accessors for stagedMedia
extension Site {

    @objc(addStagedMediaObject:)
    @NSManaged public func addToStagedMedia(_ value: StagedMedia)

    @objc(removeStagedMediaObject:)
    @NSManaged public func removeFromStagedMedia(_ value: StagedMedia)

    @objc(addStagedMedia:)
    @NSManaged public func addToStagedMedia(_ values: Set<StagedMedia>)

    @objc(removeStagedMedia:)
    @NSManaged public func removeFromStagedMedia(_ values: Set<StagedMedia>)

}

// MARK: Generated accessors for statuses
extension Site {

    @objc(addStatusesObject:)
    @NSManaged public func addToStatuses(_ value: Status)

    @objc(removeStatusesObject:)
    @NSManaged public func removeFromStatuses(_ value: Status)

    @objc(addStatuses:)
    @NSManaged public func addToStatuses(_ values: Set<Status>)

    @objc(removeStatuses:)
    @NSManaged public func removeFromStatuses(_ values: Set<Status>)

}

// MARK: Generated accessors for storyFolders
extension Site {

    @objc(addStoryFoldersObject:)
    @NSManaged public func addToStoryFolders(_ value: StoryFolder)

    @objc(removeStoryFoldersObject:)
    @NSManaged public func removeFromStoryFolders(_ value: StoryFolder)

    @objc(addStoryFolders:)
    @NSManaged public func addToStoryFolders(_ values: Set<StoryFolder>)

    @objc(removeStoryFolders:)
    @NSManaged public func removeFromStoryFolders(_ values: Set<StoryFolder>)

}

// MARK: Generated accessors for users
extension Site {

    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: User)

    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: User)

    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: Set<User>)

    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: Set<User>)

}
