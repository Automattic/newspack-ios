/// Retrieve values from nested dictionaries by keypath.
///
/// Usage: let value = dict[keypath: "a.path.to.value"]
/// Props Koke.
///
extension Dictionary {
    subscript(keyPath path: String) -> Any? {
        get {
            return path
                .components(separatedBy: ".")
                .reduce(self as Any?) { (result, path) in
                    guard let result = result as? Dictionary<String, Any> else {
                        return nil
                    }
                    return result[path]
            }
        }
    }
}
