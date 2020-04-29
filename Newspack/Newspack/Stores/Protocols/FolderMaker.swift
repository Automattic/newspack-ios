import Foundation

protocol FolderMaker {}

extension FolderMaker {

    /// Sanitize the supplied string to make it suitable to use as a folder name.
    ///
    /// - Parameter name: The string needing to be sanitized.
    /// - Returns: The sanitized version of the string.
    ///
    func sanitizedFolderName(name: String) -> String {
        var sanitizedName = name.replacingOccurrences(of: "/", with: "-")
        sanitizedName = sanitizedName.replacingOccurrences(of: ".", with: "-")
        sanitizedName = sanitizedName.trimmingCharacters(in: CharacterSet.init(charactersIn: "-"))
        return sanitizedName
    }

    /// Converts a file URL to bookkmark data.
    ///
    /// - Parameter url: A file URL.
    /// - Returns: Bookmark data or nil if there was an error.
    ///
    func bookmarkForURL(url: URL) -> Data? {
        do {
            return try url.bookmarkData()
        } catch {
            LogError(message: "Unable to get bookmarkData for url: \(url)")
        }
        return nil
    }

    /// Creates a file URL from bookmark data.
    ///
    /// - Parameters:
    ///   - bookmark: The bookmark data.
    ///   - bookmarkIsStale: An inout bool indicating if the bookmark is stale.
    /// - Returns: A URL or nil if there was an error.
    ///
    func urlFromBookmark(bookmark: Data, bookmarkIsStale: inout Bool) -> URL? {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)
            bookmarkIsStale = isStale
            return url
        } catch {
            LogError(message: "Unable to create URL from bookmark data.")
        }
        return nil
    }

}
