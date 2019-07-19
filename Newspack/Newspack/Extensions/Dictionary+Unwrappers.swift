import Foundation

/// Convenience methods for unwrapping optionals and returning default values.
///
extension Dictionary where Key == String {

    subscript(stringAtKeyPath keyPath: String) -> String {
        return self[keyPath: keyPath] as? String ?? ""
    }

    subscript(stringForKey key: String) -> String {
        return self[key] as? String ?? ""
    }

    subscript(intAtKeyPath keyPath: String) -> Int64 {
        return self[keyPath: keyPath] as? Int64 ?? 0
    }

    subscript(intForKey key: String) -> Int64 {
        return self[key] as? Int64 ?? 0
    }

    subscript(boolForKey key: String) -> Bool {
        return self[key] as? Bool ?? false
    }

}
