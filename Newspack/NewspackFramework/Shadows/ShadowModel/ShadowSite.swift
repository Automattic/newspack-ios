import Foundation

/// Stores select information about a site.
/// Facilitates storage in shared defautls.
///
public struct ShadowSite {
    public let uuid: String
    public let title: String
    public let stories: [ShadowStory]

    public var dictionary: [String: Any] {
        var storyArray = [[String: Any]]()
        for story in stories {
            storyArray.append(story.dictionary)
        }
        return [
            ModelConstants.uuid: uuid,
            ModelConstants.title: title,
            ModelConstants.stories: storyArray
        ]
    }

    public init(uuid: String, title: String, stories: [ShadowStory]) {
        self.uuid = uuid
        self.title = title
        self.stories = stories
    }

    public init(dict: [String: Any]) {
        guard
            let uuid = dict[ModelConstants.uuid] as? String,
            let title = dict[ModelConstants.title] as? String,
            let stories = dict[ModelConstants.stories] as? [[String: Any]]
        else {
            // This should never happen.
            fatalError()
        }
        self.uuid = uuid
        self.title = title

        var shadowStories = [ShadowStory]()
        for story in stories {
            shadowStories.append(ShadowStory(dict: story))
        }
        self.stories = shadowStories
    }

}
