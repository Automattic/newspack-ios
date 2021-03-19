import Foundation

/// FolderManager provides a simplified interface for working with the file system.
/// Operations are conducted relative to the current working folder.
///
public class FolderManager {

    // An instance of a FileManager
    private let fileManager: FileManager

    // All relative paths are mapped beneath thie specified rootFolder.
    private let rootFolder: URL

    // The current working folder. This will be either the rootFolder or
    // one of its children.
    public private(set) var currentFolder: URL

    /// A convenience method to create a new temporary directory and returns its URL.
    ///
    /// - Returns: A file url to the newly created temporary directory, or nil
    /// if the directory could not be created.
    ///
    public static func createTemporaryDirectory() -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: documentDirectory, create: true)
    }

    /// Initializes the FolderManager, optionally specifying its default
    /// rootFolder.
    ///
    /// - Parameter rootFolder: Optional. A URL to an existing folder to
    /// use as the root of any relative paths. The folder must be writable.
    /// If not specified the default rootFolder is the document directory.
    ///
    public init(rootFolder: URL? = nil) {
        fileManager = FileManager()

        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }

        var isDirectory: ObjCBool = false
        if
            let root = rootFolder,
            fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        {
            self.rootFolder = root
            if !fileManager.isWritableFile(atPath: root.path) {
                LogWarn(message: "The specified root folder may not be writable.")
            }
        } else {
            self.rootFolder = documentDirectory
        }

        currentFolder = self.rootFolder
    }

    /// Checks if a folder exists.
    ///
    /// - Parameter url: A file url to a folder.
    /// - Returns: true if the folder exists, otherwise false.
    public func folderExists(url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    /// Creates a new folder with the specified name underneath the currentFolder.
    ///
    /// - Parameters:
    ///   - path: The path, including name, of the folder to create.
    ///   - ifExistsAppendSuffix: If true, if the specified path already exists
    ///   a numberic index is appended to the path. Default is false.
    /// - Returns: The file URL of the folder or nil if the folder could not be
    /// created.
    ///
    public func createFolderAtPath(path: String, ifExistsAppendSuffix: Bool = false) -> URL? {
        let url = urlForFolderAtPath(path: path, ifExistsAppendSuffix: ifExistsAppendSuffix)

        guard !folderExists(url: url) else {
            return url
        }

        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            LogError(message: "Unable to create directory: \(url.path)")
            return nil
        }
        return url
    }

    /// Get a file URL for a folder at the specified path. Paths may be absolute
    /// or relative.  A relative path will be considered relative to the
    /// currentFolder.
    ///
    /// - Parameters:
    ///   - path: The path, including name, of the folder.
    ///   - ifExistsAppendSuffix: If true, if the specified path already exists
    ///   a numberic index is appended to the path. Default is false.
    /// - Returns: A URL
    ///
    public func urlForFolderAtPath(path: String, ifExistsAppendSuffix: Bool = false) -> URL {
        let url = URL(fileURLWithPath: path, isDirectory: true, relativeTo: currentFolder).absoluteURL

        if !ifExistsAppendSuffix || !folderExists(url: url) {
            return url
        }

        return fileManager.availableFileURL(for: path, isDirectory: true, relativeTo: currentFolder).absoluteURL
    }

    /// Sets the current folder to the specified URL provided the URL is the
    /// root directory or one of its children.
    ///
    /// - Parameter url: A file url.
    /// - Returns: true if successful, false otherwise.
    ///
    @discardableResult
    public func setCurrentFolder(url: URL) -> Bool {
        var didSetCurrentFolder = false

        let relation = UnsafeMutablePointer<FileManager.URLRelationship>.allocate(capacity: 1)

        do {
            try fileManager.getRelationship(relation, ofDirectoryAt: rootFolder, toItemAt: url)

            if relation.pointee != .other {
                currentFolder = url
                didSetCurrentFolder = true
            }
        } catch {
            LogError(message: "Error checking folder relationships. \(error)")
        }

        relation.deallocate()

        return didSetCurrentFolder
    }

    /// Reset the current folder to the root folder.
    ///
    public func resetCurrentFolder() {
        setCurrentFolder(url: rootFolder)
    }

    /// Get a list of the folders at the specified URL. Only folders are returned
    /// other file system items are ignored.
    ///
    /// - Parameter url: A file URL to the parent folder.
    /// - Returns: An array of file URLs
    ///
    public func enumerateFolders(url: URL) -> [URL] {
        var folders = [URL]()
        let keys: [URLResourceKey] = [.isDirectoryKey]
        do {
            folders = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: .skipsHiddenFiles).filter {
                return try $0.resourceValues(forKeys: Set(keys)).isDirectory!
            }.map {
                return $0.resolvingSymlinksInPath()
            }
        } catch {
            LogError(message: "Error getting contents of \(url): \(error)")
        }

        return folders
    }

    /// Get a list of the folder contents at the specified URL.
    ///
    /// - Parameter url: A file URL to the parent folder.
    /// - Returns: An array of file URLs
    ///
    public func enumerateFolderContents(url: URL) -> [URL] {
        var contents = [URL]()
        do {
            contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).map {
                return $0.resolvingSymlinksInPath()
            }
        } catch {
            LogError(message: "Error getting contents of folder at \(url): \(error)")
        }

        return contents
    }

    /// Delete the folder at the specified file URL. If the URL is not a folder
    /// it will not be deleted.
    ///
    /// - Parameter source: A file URL.
    /// - Returns: true if the folder was deleted, otherwise false
    ///
    @discardableResult
    public func deleteFolder(at source: URL) -> Bool {
        guard folderExists(url: source) else {
            return false
        }

        return deleteItem(at: source)
    }

    /// Delete the contents of the specified folder.
    ///
    /// - Parameter folder: The fileURL pointing to the folder whose contents should be deleted.
    /// - Returns: True if successful. False if there were any errors.
    ///
    public func deleteContentsOfFolder(folder: URL) -> Bool {
        var success = true
        let arr = enumerateFolderContents(url: folder)
        for item in arr {
            if !deleteItem(at: item) {
                success = false
            }
        }
        return success
    }

    /// Delete the item at the specified file URL
    ///
    /// - Parameter source: A file URL.
    /// - Returns: true if the item was deleted, otherwise false
    ///
    @discardableResult
    public func deleteItem(at source: URL) -> Bool {
        // Do not perform a delete operation on anything outside of our root folder.
        if !folder(rootFolder, contains: source) {
            LogError(message: "Source item for deletion: \(source) is outside of the root folder: \(rootFolder)")
            return false
        }

        do {
            try fileManager.removeItem(at: source)
            return true
        } catch {
            LogError(message: "Error removing item. \(error)")
        }

        return false
    }

    /// Move the item at the specified source file URL to the specified destination.
    ///
    /// - Parameter source: A file URL.
    /// - Parameter destination: A file URL.
    /// - Returns: true if the item was moved, otherwise false
    ///
    @discardableResult
    public func moveItem(at source: URL, to destination: URL) -> Bool {
        do {
            try fileManager.moveItem(at: source, to: destination)
            return true
        } catch {
            LogError(message: "Unable to move file at \(source) to \(destination).  Error: \(error)")
        }

        return false
    }

    /// Move the folder at the specified URL to a new location.
    ///
    /// - Parameters:
    ///   - source: The location of the folder to move.
    ///   - destination: The new location for the folder.
    /// - Returns: true if successful, false otherwise
    ///
    public func moveFolder(at source: URL, to destination: URL) -> Bool {
        let name = sanitizedFolderName(name: destination.lastPathComponent)
        guard isValidFolderName(name: name) else {
            return false
        }

        let destination = destination.deletingLastPathComponent().appendingPathComponent(name, isDirectory: true)

        guard folderExists(url: source) && !folderExists(url: destination) else {
            return false
        }

        do {
            try fileManager.moveItem(at: source, to: destination)
            return true
        } catch {
            LogError(message: "Error moving folder \(source) to \(destination)")
        }

        return false
    }

    /// Rename the folder at the specified url to the specified name.
    ///
    /// - Parameters:
    ///   - source: The url of the folder to rename.
    ///   - name: The new name.
    /// - Returns: The new URL of the folder, or nil if the folder could not be
    /// renamed.
    ///
    public func renameFolder(at source: URL, to name: String) -> URL? {
        let sanitizedName = sanitizedFolderName(name: name)
        var newURL = source.deletingLastPathComponent().appendingPathComponent(sanitizedName, isDirectory: true)

        if folderExists(url: newURL) {
            newURL = urlForFolderAtPath(path: name, ifExistsAppendSuffix: true)
        }

        if moveFolder(at: source, to: newURL) {
            return newURL
        }
        return nil
    }

    /// Returns a sanitized version of the specified string.
    ///
    /// - Parameter name: A prospective folder name.
    /// - Returns: The sanitized version of the name.
    ///
    public func sanitizedFolderName(name: String) -> String {
        var sanitizedName = name.replacingOccurrences(of: "/", with: "-")
        sanitizedName = sanitizedName.replacingOccurrences(of: ".", with: "-")
        sanitizedName = sanitizedName.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return sanitizedName
    }

    /// Checks if a string is a valid folder name.
    ///
    /// - Parameter name: The prospective folder name
    /// - Returns: true if valid, otherwise false.
    ///
    func isValidFolderName(name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }

    /// Check if a folder at one url contains the item at anoter url.
    /// - Parameters:
    ///   - folder: A file URL to the folder.
    ///   - descendent: A file URL to the descendent item.
    /// - Returns: true if the folder contains the descendent, otherwise false.
    ///
    func folder(_ folder: URL, contains descendent: URL) -> Bool {
        let relation = UnsafeMutablePointer<FileManager.URLRelationship>.allocate(capacity: 1)
        do {
            try fileManager.getRelationship(relation, ofDirectoryAt: folder, toItemAt: descendent)
        } catch {
            LogError(message: "Error checking folder relationships. \(error)")
            return false
        }
        return relation.pointee == .contains
    }

    /// A convenience method to see if the current folder contains the item
    /// specified by the supplied file URL.
    /// - Parameter descendent: A file URL to a child item.
    /// - Returns: true if the current folder contains the child, otherwise false.
    ///
    func currentFolderContains(_ descendent: URL) -> Bool {
        return folder(currentFolder, contains: descendent)
    }

    /// Check if one folder is the immediate parent of another folder.
    ///
    /// - Parameters:
    ///   - parent: A file URL to the parent folder.
    ///   - child: A file URL to the child folder.
    /// - Returns: true if there is a parent/child relationship.
    ///
    public func folder(_ folder: URL, isParentOf child: URL) -> Bool {
        let parent = child.deletingLastPathComponent()
        guard
            let folderRef = folder.getFileReferenceURL(),
            let parentRef = parent.getFileReferenceURL()
        else {
            return false
        }
        return folderRef.isEqual(parentRef)
    }

    /// Converts a file URL to bookkmark data.
    ///
    /// - Parameter url: A file URL.
    /// - Returns: Bookmark data or nil if there was an error.
    ///
    public func bookmarkForURL(url: URL) -> Data? {
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
    public func urlFromBookmark(bookmark: Data, bookmarkIsStale: inout Bool) -> URL? {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)
            bookmarkIsStale = isStale

            if isTrashed(url: url) {
                bookmarkIsStale = true
            }

            return url
        } catch {
            LogError(message: "Unable to create URL from bookmark data.")
        }
        return nil
    }

    /// A convenience wrapper around urlFromBookMark(bookmark:bookmarkIsStale:)
    /// Only call this when confident the value of bookmarkIsStale: is not relevant.
    ///
    /// - Parameter bookmark: The bookmark data.
    /// - Returns: A URL or nil if there was an error.
    ///
    public func urlFromBookmark(bookmark: Data) -> URL? {
        var isStale = false
        return urlFromBookmark(bookmark: bookmark, bookmarkIsStale: &isStale)
    }

    /// Check if a file resource has been trashed.
    ///
    /// - Parameter url: A file URL.
    /// - Returns: True the URL points to an object in the .Trash directory, otherwise false.
    ///
    func isTrashed(url: URL) -> Bool {
        // There doesn't seem to be usable API for determining if a file URL
        // points to something that's been trashed (but not deleted).
        // We want to treat these as stale regardless, so this will have to
        // do for now.
        // The string literal seems to be consistent regardless of the system
        // language, i.e. it does not reference a system folder's display name.
        return url.pathComponents.contains(".Trash")
    }

}
