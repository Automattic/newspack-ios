import UIKit

struct TextFieldModel {
    let title: String
    let text: String?
    let placeholder: String?
    let instructions: String
    let saveHandler: (_ newValue: String?) -> Void
}

class TextFieldViewController: UITableViewController {

    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

    private var textField: UITextField?
    var model: TextFieldModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let _ = model else {
            fatalError()
        }

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
        navigationItem.title = model.title
    }

    private func configureSave() {
        saveButton.isEnabled = textField?.text != model.text
    }

}

// MARK: - Actions

extension TextFieldViewController {

    @IBAction func handleSaveTapped(sender: UIBarButtonItem) {
        saveChanges()
        dismiss()
    }

    @IBAction func handleCancelTapped(sender: UIBarButtonItem) {
        dismiss()
    }

    private func saveChanges() {
        model.saveHandler(textField?.text)
    }

    private func dismiss() {
        if let _ = presentingViewController {
            dismiss(animated: true, completion: nil)
            return
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table view data source

extension TextFieldViewController {

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
            self?.configureSave()
        })

        textField?.placeholder = model.placeholder
        textField?.text = model.text

        configureSave()

        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        textField?.becomeFirstResponder()
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return model.instructions
    }

}

// MARK: - Text Field Delegate

extension TextFieldViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveChanges()
        dismiss()
        return true
    }

}
