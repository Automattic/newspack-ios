import UIKit

class FolderViewController: UITableViewController {

    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

    var syncToggle: UISwitch?
    var textField: UITextField?
    var storyUUID: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCells()
        configureStyle()
        configureTitle()
    }

    private func configureCells() {
        tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: TextFieldTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
    }

    private func configureStyle() {
        Appearance.style(view: view, tableView: tableView)
    }

    private func configureTitle() {
        if let _ = storyUUID {
            navigationItem.title = NSLocalizedString("Edit Story", comment: "Noun. Title of a screen for editing a story.")
        } else {
            navigationItem.title = NSLocalizedString("New Story", comment: "Noun. Title of a screen for creating a new story.")
        }
    }

    enum FolderSections: Int, CaseIterable {
        case title
        case sync

        static func count() -> Int {
            return FolderSections.allCases.count
        }
    }
}

// MARK: - Actions

extension FolderViewController {

    @IBAction func handleSaveTapped(sender: UIBarButtonItem) {
        saveStory()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func handleCancelTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func saveStory() {
        guard let title = textField?.text, title.count > 0 else {
            return
        }
        let autoSync = syncToggle?.isOn == false ? false : true

        if let uuid = storyUUID {
            // Edit story action
            let action = FolderAction.updateStoryFolder(folderID: uuid, name: title, autoSyncAssets: autoSync)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        } else {
            // New story action
            let action = FolderAction.createStoryFolderNamed(path: title, addSuffix: true, autoSyncAssets: autoSync)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }
    }

}

// MARK: - Table view data source

extension FolderViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return FolderSections.count()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch FolderSections(rawValue: indexPath.section) {
        case .title:
            return cellForTitleSection(at: indexPath)
        case .sync:
            return cellForSyncSection(at: indexPath)
        default:
            // This shouldn't happen.
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard
            indexPath.section == FolderSections.sync.rawValue,
            let toggle = syncToggle
        else {
                return
        }
        toggle.setOn(!toggle.isOn, animated: true)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == FolderSections.title.rawValue {
            textField?.becomeFirstResponder()
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch FolderSections(rawValue: section) {
        case .title:
            return textForTitleSectionFooter()
        case .sync:
            return textForSyncSectionFooter()
        default:
            return nil
        }
    }

    func cellForTitleSection(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldTableViewCell.reuseIdentifier, for: indexPath) as! TextFieldTableViewCell
        Appearance.style(cell: cell)
        cell.delegate = self

        // We only have one cell, so this works okay.
        textField = cell.textField
        textField?.on(.editingChanged, call: { [weak self] textField in
            self?.saveButton.isEnabled = (textField.text?.characterCount ?? 0) > 0
        })

        let placeholder = NSLocalizedString("New Story", comment: "Noun. This is the default title of a new story before the author provides a title.")
        textField?.placeholder = placeholder

        if let uuid = storyUUID, let story = StoreContainer.shared.folderStore.getStoryFolderByID(uuid: uuid) {
            textField?.text = story.name
        } else {
            textField?.text = placeholder
        }

        return cell
    }

    func cellForSyncSection(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.reuseIdentifier, for: indexPath) as! SwitchTableViewCell
        Appearance.style(cell: cell)

        var toggleOn = true
        if let uuid = storyUUID, let story = StoreContainer.shared.folderStore.getStoryFolderByID(uuid: uuid) {
            toggleOn = story.autoSyncAssets
        }

        let title = NSLocalizedString("Upload assets immediately", comment: "A short prompt providing instruction to the user.")
        cell.configureCell(title: title, toggleOn: toggleOn)
        syncToggle = cell.toggle
        cell.selectionStyle = .none

        return cell
    }

    func textForTitleSectionFooter() -> String {
        if let _ = storyUUID {
            return NSLocalizedString("Change the story's title.", comment: "A short prompt providing instruction to the user.")
        } else {
            return NSLocalizedString("Give the story a title.", comment: "A short prompt providing instruction to the user.")
        }
    }

    func textForSyncSectionFooter() -> String {
        return NSLocalizedString("When enabled, newly added assets must be manually uploaded.", comment: "A short statement describing the effect of a toggle control.")
    }

}

// MARK: - Text Field Delegate

extension FolderViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveStory()
        return true
    }

}
