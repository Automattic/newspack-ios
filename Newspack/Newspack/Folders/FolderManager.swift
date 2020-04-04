import Foundation

/// FolderManager provides a simplified interface for working with the file system.
/// Operations are conducted relative to the current working folder.
///
class FolderManager {

    // An instance of a FileManager
    private let fileManager: FileManager

    // All relative paths are mapped beneath thie specified rootFolder.
    private let rootFolder: URL

    // The current working folder. This will be either the rootFolder or
    // one of its children.
    private var currentFolder: URL

    /// A convenience method to create a new temporary directory and returns its URL.
    ///
    /// - Returns: A file url to the newly created temporary directory, or nil
    /// if the directory could not be created.
    ///
    static func createTemporaryDirectory() -> URL? {
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
    init(rootFolder: URL? = nil) {
        fileManager = FileManager()

        guard let documentDirectory  = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }

        var isDirectory: ObjCBool = false
        if
            let root = rootFolder,
            fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
            isDirectory.boolValue,
            fileManager.isWritableFile(atPath: root.path)
        {
            self.rootFolder = root
        } else {
            self.rootFolder = documentDirectory
        }

        currentFolder = self.rootFolder
    }

    /// Checks if a folder exists.
    ///
    /// - Parameter url: A file url to a folder.
    /// - Returns: true if the folder exists, otherwise false.

    func folderExists(url: URL) -> Bool {
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
    func createFolderAtPath(path: String, ifExistsAppendSuffix: Bool = false) -> URL? {
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
    func urlForFolderAtPath(path: String, ifExistsAppendSuffix: Bool = false) -> URL {
        var url = URL(fileURLWithPath: path, isDirectory: true, relativeTo: currentFolder)

        if !ifExistsAppendSuffix || !folderExists(url: url) {
            return url
        }

        var newPath = path
        var counter = 1
        repeat {
            counter = counter + 1
            newPath = "\(path) \(counter)"
            url = URL(fileURLWithPath: newPath, isDirectory: true, relativeTo: currentFolder)
        } while folderExists(url: url)

        return url
    }

    /// Sets the current folder to the specified URL provided the URL is the
    /// root directory or one of its children.
    ///
    /// - Parameter url: A file url.
    /// - Returns: true if successful, false otherwise.
    ///
    func setCurrentFolder(url: URL) -> Bool {
        var didSetCurrentFolder = false

        let relation = UnsafeMutablePointer<FileManager.URLRelationship>.allocate(capacity: 1)

        try? fileManager.getRelationship(relation, ofDirectoryAt: rootFolder, toItemAt: url)

        if relation.pointee != .other {
            currentFolder = url
            didSetCurrentFolder = true
        }

        relation.deallocate()

        return didSetCurrentFolder
    }
}
