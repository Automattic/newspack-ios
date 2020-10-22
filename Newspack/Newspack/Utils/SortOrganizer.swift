import Foundation
import CoreData
import NewspackFramework

/// A struct that defines a single sort rule.
///
struct SortRule {
    /// The attributed of an NSManagedObject entity to sort by.
    let field: String
    /// The name to display in the UI
    let displayName: String
    /// Whether to sort ascending or not.
    var ascending: Bool
    /// Whether to sort ascending or not.
    let caseInsensitive: Bool

    init(field: String, displayName: String, ascending: Bool, caseInsensitive: Bool = false) {
        self.field = field
        self.displayName = displayName
        self.ascending = ascending
        self.caseInsensitive = caseInsensitive
    }

    /// A convenience initializer. Use to restore a serialized sort rule from a
    /// dictionary.
    ///
    /// - Parameter dict: A dictionary with keys and values corresponding to the sort rue.
    ///
    init(dict: [String: Any]) {
        guard
            let field = dict["field"] as? String,
            let displayName = dict["displayName"] as? String,
            let ascending = dict["ascending"] as? Bool,
            let caseInsensitive = dict["caseInsensitive"] as? Bool
        else {
            // We should never get here but...
            fatalError()
        }
        self.field = field
        self.displayName = displayName
        self.ascending = ascending
        self.caseInsensitive = caseInsensitive
    }

    /// Changes the value of ascending.
    ///
    /// - Parameter value: The new value.
    ///
    mutating func setAscending(value: Bool) {
        ascending = value
    }

    /// Get a dictionary representation of the rule for serializing to storage.
    ///
    /// - Returns: A dictionary whose keys are property names and accompanying values.
    ///
    func dictionary() -> [String: Any] {
        return [
            "field": field,
            "displayName": displayName,
            "ascending": ascending,
            "caseInsensitive": caseInsensitive
        ]
    }
}

/// Defines all the information necessary for a single sort mode.
/// A sort mode is a collection of one or more sort rules.
/// Includes the title of the sort mode, and sort descriptors.
///
class SortMode {

    /// The user facing title for the sort mode.
    let title: String

    /// Whether the first sort rule should be used for defining sections.
    let hasSections: Bool

    /// A closure that accepts a string and returns a string. it is used to
    /// exchange the value of a NSFetchedResultsSectionInfo's name to a user
    /// facing string.
    private let sectionNameResolver: ((_ name: String) -> String)?

    /// The array of SortRules
    private(set) var rules: [SortRule]

    /// The string to use for the UserDefaults key when serializing.
    private let defaultsKey: String

    /// An array of NSSortDescriptors based off of the current rules.
    var descriptors: [NSSortDescriptor] {
        var arr = [NSSortDescriptor]()
        for rule in rules {
            if rule.caseInsensitive {
                arr.append(NSSortDescriptor(key: rule.field, ascending: rule.ascending, selector: #selector(NSString.localizedCaseInsensitiveCompare)))
            } else {
                arr.append(NSSortDescriptor(key: rule.field, ascending: rule.ascending))
            }
        }
        return arr
    }

    /// A convienince property for getting the value to use for an NSFetchedResultsController's sectionKeyNamePath
    var sectionNameKeyPath: String? {
        guard hasSections else {
            return nil
        }
        return rules.first?.field
    }

    init(defaultsKey: String, title: String, rules: [SortRule], hasSections: Bool, resolver: ((_ name: String) -> String)?) {
        self.defaultsKey = defaultsKey
        self.title = title
        self.hasSections = hasSections
        self.rules = rules
        sectionNameResolver = resolver

        // Let whatever is currently saved override what is passed.
        if let savedRules = savedRules() {
            self.rules = savedRules
        }

        // Store just in case there is nothing stored.
        save()
    }

    /// Retrieve the title to use for a NSFetchedResultSectionInfo's name.
    ///
    /// - Parameter section: An NSFetchedResultsSectionInfo instance.
    ///
    /// - Returns: The string to use for the section. This will be the value returned
    /// by passing the section's name to the sectionNameResolver closure passed
    /// to init. If a closure was not set, this method returns nil.
    ///
    func title(for section: NSFetchedResultsSectionInfo) -> String {
        guard let resolver = sectionNameResolver else {
            return ""
        }
        return resolver(section.name)
    }

    /// Get's the SortRules currently stored in UserDefaults.
    ///
    /// - Returns: An array of SortRules or nil.
    ///
    func savedRules() -> [SortRule]? {
        guard let arr = UserDefaults.shared.object(forKey: defaultsKey) as? [[String: Any]] else {
            return nil
        }
        var rules = [SortRule]()
        for item in arr {
            rules.append(SortRule(dict: item))
        }
        return rules
    }

    /// Update's the ascending value of the rule for the corresponding field.
    ///
    /// - Parameters:
    ///   - field: The field of the SortRule to update.
    ///   - value: The new value for the rule's ascending property.
    ///
    func updateRule(for field: String, value: Bool) {
        // Kind of annoying, but we need to recreate the whole array just to change one rule.
        var arr = [SortRule]()

        for rule in rules {
            var rule = rule
            if rule.field == field {
                rule.setAscending(value: value)
            }
            arr.append(rule)
        }
        rules = arr

        save()
    }

    /// Set the rules for the sort mode and save the new rules to storage.
    ///
    /// - Parameter newRules: An array of SortRule instances.
    ///
    func setRules(newRules: [SortRule]) {
        rules = newRules
        save()
    }

    /// Save the current rules to UserDefaults
    ///
    private func save() {
        var arr = [[String: Any]]()
        for rule in rules {
            arr.append(rule.dictionary())
        }
        UserDefaults.shared.set(arr, forKey: defaultsKey)
    }
}

/// Manages a list of sort modes.
///
class SortOrganizer {

    /// An array of SortMode instances to manage.
    private(set) var modes: [SortMode]

    /// The currently selected index.
    private(set) var selectedIndex = 0

    /// The string to use for the UserDefaults key when serializing.
    private let defaultsKey: String

    /// A convenience access for getting the currently selected sort mode.
    var selectedMode: SortMode {
        return modes[selectedIndex]
    }

    init(defaultsKey: String, modes: [SortMode]) {
        self.defaultsKey = defaultsKey
        self.modes = modes

        selectedIndex = savedIndex()
    }

    /// Get the SortMode at the specific index.
    ///
    /// - Parameter index: The index of the desired SortMode
    ///
    /// - Returns:The specified SortMode
    ///
    func mode(at index: Int) -> SortMode {
        return modes[index]
    }

    /// Set the selected index and update UserDefaults.
    ///
    /// - Parameter index: The value of the new selected index.
    ///
    func select(index: Int) {
        guard index < modes.count else {
            return
        }
        selectedIndex = index
        UserDefaults.shared.set(index, forKey: defaultsKey)
    }

    /// Returns the current value of the index stored in UserDefaults.
    ///
    /// - Returns: The index value
    ///
    private func savedIndex() -> Int {
        return UserDefaults.shared.integer(forKey: defaultsKey)
    }
}
