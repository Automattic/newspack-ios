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
    @NSManaged public var statuses: Set<Status>!
    @NSManaged public var storyFolders: Set<StoryFolder>!
    @NSManaged public var users: Set<User>!

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
