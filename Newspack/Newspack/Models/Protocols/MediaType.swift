import Foundation

enum MediaKind {
    case image
    case video
    case audio
    case document
    case other
}

protocol MediaTypeDiscerner {
    var mimeType: String! { get }
    var details: [String: AnyObject]! { get }

    func mediaKind() -> MediaKind
}

extension MediaTypeDiscerner {
    func mediaKind() -> MediaKind {
        if mimeType.hasPrefix("image") {
            return .image
        }
        if mimeType.hasPrefix("video") {
            return .video
        }
        if mimeType.hasPrefix("audio") {
            return .audio
        }
        if mimeType.hasPrefix("text") {
            return .document
        }
        return .other
    }

    func previewURL() -> String? {
        guard
            mediaKind() == .image,
            let sizes = details["sizes"] as? [String: AnyObject],
            let medium = sizes["medium"] as? [String: AnyObject],
            let sourceURL = medium["source_url"] as? String
        else {
            return nil
        }
        return sourceURL
    }
}
