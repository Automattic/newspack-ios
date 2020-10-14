import Foundation
import CoreServices

extension URL {

    var utiFromPathExtension: String? {
        let ext = pathExtension as NSString
        guard ext.length > 0 else {
            return nil
        }
        return UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil)?.takeRetainedValue() as String?
    }

    var mimeType: String? {
        guard let uti = utiFromPathExtension else {
            return nil
        }
        return UTTypeCopyPreferredTagWithClass(uti as NSString, kUTTagClassMIMEType)?.takeRetainedValue() as String?
    }

    var isImage: Bool {
        guard let uti = utiFromPathExtension as NSString? else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeImage)
    }

    var isAudio: Bool {
        guard let uti = utiFromPathExtension as NSString? else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeAudio)
    }

    var isVideo: Bool {
        guard let uti = utiFromPathExtension as NSString? else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeMovie)
    }

    var isPDF: Bool {
        guard let uti = utiFromPathExtension as NSString? else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypePDF)
    }

}
