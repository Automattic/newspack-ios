import Foundation

extension FileManager {

    public func availableFileURL(for path: String, isDirectory: Bool, relativeTo relURL: URL?) -> URL {
        var url = URL(fileURLWithPath: path, isDirectory: isDirectory, relativeTo: relURL).absoluteURL

        if !fileExists(atPath: url.path) {
            return url
        }

        var counter = 1
        repeat {
            let newPath = appendSuffix(suffix: String(counter), to: path)
            url = URL(fileURLWithPath: newPath, isDirectory: isDirectory, relativeTo: relURL).absoluteURL
            counter = counter + 1
        } while fileExists(atPath: url.path)

        return url
    }

    private func appendSuffix(suffix: String, to path: String) -> String {
        guard path.contains(".") else {
            return path + suffix
        }

        var parts = path.components(separatedBy: ".")
        let str = parts[parts.count - 2] + suffix
        parts[parts.count - 2] = str

        return parts.joined(separator: ".")
    }

}
