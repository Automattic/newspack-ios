import UIKit

class FolderViewController: UITableViewController {

    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

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

}

// MARK: - Actions

extension FolderViewController {

    @IBAction func handleSaveTapped(sender: UIBarButtonItem) {
        saveStoryTitle()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func handleCancelTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func saveStoryTitle() {
        guard let title = textField?.text, title.count > 0 else {
            return
        }

        if let uuid = storyUUID {
            // Edit story action
            let action = FolderAction.renameStoryFolder(folderID: uuid, name: title)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        } else {
            // New story action
            let action = FolderAction.createStoryFolderNamed(path: title, addSuffix: true)
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }
    }

}

// MARK: - Table view data source

extension FolderViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        textField?.becomeFirstResponder()
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let _ = storyUUID {
            return NSLocalizedString("Change the story's title.", comment: "A short prompt providing instruction to the user.")
        } else {
            return NSLocalizedString("Give the story a title.", comment: "A short prompt providing instruction to the user.")
        }
    }

}

// MARK: - Text Field Delegate

extension FolderViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveStoryTitle()
        dismiss(animated: true, completion: nil)
        return true
    }

}
