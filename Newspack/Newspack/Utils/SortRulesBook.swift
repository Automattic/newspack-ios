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
    private var defaultSectionKey: String?
    private let defaults: SortRules
    private let caseInsensitiveFields: [String]

    // Get the current sectionNameKeyPath if one exists.
    //
    var sectionKey: String? {
        guard
            let dict = UserDefaults.shared.dictionary(forKey: storageKey),
            let key = dict[Constants.sectionKey] as? String
        else {
            return defaultSectionKey
        }
        return key
    }

    /// Get a list of NSSortDescriptors derived from the current SortRules.
    ///
    /// - Returns: An array of NSSortDescriptors
    ///
    var descriptors: [NSSortDescriptor] {
        let dict = rules

        var arr = [NSSortDescriptor]()
        for (key, value) in dict {
            if caseInsensitiveFields.contains(key) {
                arr.append(NSSortDescriptor(key: key, ascending: value, selector: #selector(NSString.caseInsensitiveCompare)))
            } else {
                arr.append(NSSortDescriptor(key: key, ascending: value))
            }
        }

        return arr
    }

    /// Returns the current SortRules
    ///
    /// - Returns: An array of SortRules
    ///
    var rules: SortRules {
        guard
            let dict = UserDefaults.shared.dictionary(forKey: storageKey),
            let rules = dict[Constants.rules] as? SortRules
        else {
            return defaults
        }
        return rules
    }

    /// Creates a new instance of a SortRulesManager
    ///
    /// - Parameters:
    ///   - storageKey: A key to use with UserDefaults.
    ///   - fields: A list of allowed fields to sort by.
    ///   - defaults: Default SortRules.  This should not be empty.
    ///   - sectionKey: A sectionNameKeyPath for ordering results into sections in a FetchedRsultsController.
    ///   - caseInsensitiveFields: Optional. An array of case insensitive fields. These should only be string fields.
    ///
    init(storageKey: String, fields: [String], defaults: SortRules, sectionKey: String? = nil, caseInsensitiveFields: [String] = []) {
        self.storageKey = storageKey
        self.fields = fields
        self.defaults = defaults
        self.defaultSectionKey = sectionKey
        self.caseInsensitiveFields = caseInsensitiveFields

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
        saveRules(rules: defaults, sectionKey: sectionKey)
    }

    /// Check if there is an existing rule matching the specified field and value.
    /// - Parameters:
    ///   - field: The field name.
    ///   - ascending: true for ascending, flase for descending.
    /// - Returns: True if a rule exists, otherwise false.
    ///
    func hasRule(field: String, ascending: Bool) -> Bool {
        return rules.contains { element -> Bool in
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

        var dict = rules
        dict[field] = ascending
        saveRules(rules: dict, sectionKey: sectionKey)
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
        saveRules(rules: dict, sectionKey: sectionKey)
    }

    /// Sets the section key. Note that the key must be one of the allowed fields.
    ///
    /// - Parameter key: The field to use for sections, or nil.
    ///
    func setSectionKey(key: String?) {
        // If the key is not nil, and it isn't included in the list of allowed
        // fields just return.
        if let key = key, !fields.contains(key) {
            return
        }
        saveRules(rules: rules, sectionKey: key)
    }

    /// Save Rules
    ///
    /// - Parameters:
    ///   - rules: The SortRules to save.
    ///   - sectionKey: The section key to save.
    ///
    private func saveRules(rules: SortRules, sectionKey: String?) {
        var dict: [String: Any?] = [
            Constants.rules: rules
        ]

        if let key = sectionKey {
            dict[Constants.sectionKey] = key
        }

        UserDefaults.shared.set(dict, forKey: storageKey)
    }

    /// Private constants.
    private struct Constants {
        static let sectionKey = "sectionKey"
        static let rules = "rules"
    }
}
