import Foundation
import CoreData
@testable import Newspack

class ModelFactory {

    class func getTestSite(context: NSManagedObjectContext) -> Site {
        let site = Site(context: context)

        site.uuid = UUID()
        site.url = "url"
        site.title = "site"
        site.summary = "description"
        site.timezone = "timezone"
        site.dateFormat = "dateFormat"
        site.timeFormat = "timeFormat"
        site.startOfWeek = "startOfWeek"
        site.language = "language"
        site.useSmilies = true
        site.defaultCategory = 1
        site.defaultPostFormat = 1
        site.postsPerPage = 10
        site.defaultPingStatus = "defaultPingStatus"
        site.defaultCommentStatus = "defaultCommentStatus"

        return site
    }

    class func getTestAccountDetails(context: NSManagedObjectContext) -> AccountDetails {
        let details = AccountDetails(context: context)

        details.userID = 1
        details.name = "name"
        details.firstName = "firstName"
        details.lastName = "lastName"
        details.nickname = "nickname"
        details.email = "email"
        details.avatarUrls = [String: String]()
        details.link = "link"
        details.locale = "locale"
        details.slug = "slug"
        details.summary = "description"
        details.url = "url"
        details.username = "username"
        details.registeredDate = "registeredDate"

        return details
    }

}
