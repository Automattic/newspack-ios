import Foundation

typealias SortRules = [String: Bool]

/// A class for wrangling list sort rules. An instance is configured with a unique
/// storage key used to record sort rules in UserDefaults, an array of field names
/// that may be sorted, and a default sort rule.
/// Sort rules are serialized to UserDefaults and the list is used to
/// generate an array of NSSortDescriptors for use with FetchRequests.
///
class SortRulesBook {

    private let storageKey: String
    private let fields: [String]
    private let defaults: SortRules

    /// Creates a new instance of a SortRulesManager
    ///
    /// - Parameters:
    ///   - storageKey: A key to use with UserDefaults.
    ///   - fields: A list of allowed fields to sort by.
    ///   - defaults: Default SortRules.  This should not be empty.
    ///
    init(storageKey: String, fields: [String], defaults: SortRules) {
        self.storageKey = storageKey
        self.fields = fields
        self.defaults = defaults

        setup()
    }

    /// Responsible for priming UserDefaults if no sort rules are currently
    /// stored there for the `key`.  Should only be called once during init.
    ///
    private func setup() {
        guard UserDefaults.shared.dictionary(forKey: storageKey) == nil else {
            return
        }
        reset()
    }

    /// Resets the stored SortRules to the default rules.
    ///
    func reset() {
        UserDefaults.shared.set(defaults, forKey: storageKey)
    }

    /// Get a list of NSSortDescriptors derived from the current SortRules.
    ///
    /// - Returns: An array of NSSortDescriptors
    ///
    func descriptors() -> [NSSortDescriptor] {
        let dict = rules()

        var arr = [NSSortDescriptor]()
        for (key, value) in dict {
            arr.append(NSSortDescriptor(key: key, ascending: value))
        }

        return arr
    }

    /// Check if there is an existing rule matching the specified field and value.
    /// - Parameters:
    ///   - field: The field name.
    ///   - ascending: true for ascending, flase for descending.
    /// - Returns: True if a rule exists, otherwise false.
    ///
    func hasRule(field: String, ascending: Bool) -> Bool {
        return rules().contains { element -> Bool in
            return element.key == field && element.value == ascending
        }
    }

    /// Creates or updates a SortRule and stores it to UserDefaults.
    ///
    /// - Parameters:
    ///   - field: The name of the field to sort by. This must be one of the items in the fields array.
    ///   - ascending: true if the sort order should be ascending, or false if it should be descending
    ///
    func setRule(field: String, ascending: Bool) {
        guard fields.contains(field) else {
            return
        }

        guard !hasRule(field: field, ascending: ascending) else {
            return
        }

        var dict = rules()
        dict[field] = ascending
        UserDefaults.shared.set(dict, forKey: storageKey)
    }

    /// Sets the stored rules. Note that any keys missing from fields will be
    /// excluded.
    ///
    /// - Parameter rules: A SortRules instance.
    ///
    func setRules(rules: SortRules) {
        var dict = SortRules()
        for rule in rules {
            if fields.contains(rule.key) {
                dict[rule.key] = rule.value
            }
        }
        UserDefaults.shared.set(dict, forKey: storageKey)
    }

    /// Returns the current SortRules
    ///
    /// - Returns: An array of SortRules
    ///
    func rules() -> SortRules {
        guard let dict = UserDefaults.shared.dictionary(forKey: storageKey) as? SortRules else {
            return defaults
        }
        return dict
    }

}
