import Foundation
import CoreData

/// A struct that defines a single sort rule.
///
struct SortRule {
    let field: String
    let displayName: String
    var ascending: Bool

    init(field: String, displayName: String, ascending: Bool) {
        self.field = field
        self.displayName = displayName
        self.ascending = ascending
    }

    init(dict: [String: Any]) {
        guard
            let field = dict["field"] as? String,
            let displayName = dict["displayName"] as? String,
            let ascending = dict["ascending"] as? Bool
        else {
            // We should never get here but...
            fatalError()
        }
        self.field = field
        self.displayName = displayName
        self.ascending = ascending
    }

    mutating func setAscending(value: Bool) {
        ascending = value
    }

    func dictionary() -> [String: Any] {
        return [
            "field": field,
            "displayName": displayName,
            "ascending": ascending
        ]
    }
}

/// Defines all the information necessary for a single sort mode.
/// A sort mode is a collection of one or more sort rules.
/// Includes the title of the sort mode, and sort descriptors.
///
class SortMode {

    let title: String

    let hasSections: Bool

    private let sectionNameResolver: ((_ name: String) -> String)?

    private(set) var rules: [SortRule]

    let defaultsKey: String

    var descriptors: [NSSortDescriptor] {
        var arr = [NSSortDescriptor]()
        for rule in rules {
            arr.append(NSSortDescriptor(key: rule.field, ascending: rule.ascending))
        }
        return arr
    }

    var sectionNameKeyPath: String? {
        guard hasSections else {
            return nil
        }
        return rules.first?.field
    }

    init(defaultsKey: String, title: String, rules: [SortRule], hasSections: Bool, resolver: @escaping ((_ name: String) -> String)) {
        self.defaultsKey = defaultsKey
        self.title = title
        self.hasSections = hasSections
        self.rules = rules
        sectionNameResolver = resolver

        if let savedRules = savedRules() {
            self.rules = savedRules
        }

        save()
    }

    func title(for section: NSFetchedResultsSectionInfo) -> String {
        guard let resolver = sectionNameResolver else {
            return ""
        }
        return resolver(section.name)
    }

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

    private(set) var modes: [SortMode]

    private(set) var selectedIndex = 0

    private let defaultsKey: String

    var selectedMode: SortMode {
        return modes[selectedIndex]
    }

    init(defaultsKey: String, modes: [SortMode]) {
        self.defaultsKey = defaultsKey
        self.modes = modes

        selectedIndex = savedIndex()
    }

    func mode(at index: Int) -> SortMode {
        return modes[index]
    }

    func select(index: Int) {
        guard index < modes.count else {
            return
        }
        selectedIndex = index
        UserDefaults.shared.set(index, forKey: defaultsKey)
    }

    private func savedIndex() -> Int {
        return UserDefaults.shared.integer(forKey: defaultsKey)
    }
}
