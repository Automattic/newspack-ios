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

}
