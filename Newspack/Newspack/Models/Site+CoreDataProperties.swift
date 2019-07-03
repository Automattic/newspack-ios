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
    @NSManaged public var categories: Set<Category>!
    @NSManaged public var media: Set<Media>!
    @NSManaged public var pages: Set<Page>!
    @NSManaged public var posts: Set<Post>!
    @NSManaged public var statuses: Set<Status>!
    @NSManaged public var tags: Set<Tag>!
    @NSManaged public var users: Set<User>!

}

// MARK: Generated accessors for categories
extension Site {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: Set<Category>)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: Set<Category>)

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

// MARK: Generated accessors for tags
extension Site {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: Set<Tag>)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: Set<Tag>)

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
