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
            fileManager.fileExists(atPath: root.absoluteString, isDirectory: &isDirectory),
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
    /// - Parameter folderName: The name of the folder to create.
    /// - Returns: The file URL of the folder or nil if the folder could not be created.
    ///
    func createFolderAtPath(path: String) -> URL? {
        let url = urlForFolderAtPath(path: path)
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
    /// - Parameter path: A path to a folder.
    /// - Returns: A URL
    ///
    func urlForFolderAtPath(path: String) -> URL {
        return URL(fileURLWithPath: path, isDirectory: true, relativeTo: currentFolder)
    }
}
