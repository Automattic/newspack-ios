import UIKit

class TextNoteViewController: UIViewController {

    private struct Constants {
        static let encodedTextKey = "encodedTextKey"
        static let encodedAssetID = "encodedAssetID"
    }

    @IBOutlet var textView: UITextView!

    var asset: StoryAsset?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavbar()
        configureToolbar()
        configureTextView()
        configureStyle()
        configureInsets()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveOrDiscard()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            self.configureInsets()
        })
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        if let asset = asset {
            coder.encode(asset.uuid.uuidString, forKey: Constants.encodedAssetID)
        }

        if !textView.text.isEmpty {
            coder.encode(textView.text, forKey: Constants.encodedTextKey)
        }
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)

        if let encodedID = coder.decodeObject(forKey: Constants.encodedAssetID) as? String,
           let uuid = UUID(uuidString: encodedID) {
            asset = StoreContainer.shared.assetStore.getStoryAssetByID(uuid: uuid)
        }

        if let text = coder.decodeObject(forKey: Constants.encodedTextKey) as? String {
            textView.text = text
        }
    }

    func configureNavbar() {
        navigationItem.title = NSLocalizedString("Text Note", comment: "Noun. The title of a screen that shows the contents of a text note.")
    }

    func configureToolbar() {
        navigationController?.setToolbarHidden(true, animated: true)
    }

    func configureStyle() {
        Appearance.style(textView: textView)
        configureInsets()
    }

    func configureInsets() {
        guard UIDevice().userInterfaceIdiom == .pad else {
            textView.textContainerInset = UIEdgeInsets.init(top: 16, left: 16, bottom: 16, right: 16)
            return
        }

        if UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape == true {
            textView.textContainerInset = UIEdgeInsets.init(top: 16, left: 120, bottom: 16, right: 120)
        } else {
            textView.textContainerInset = UIEdgeInsets.init(top: 16, left: 60, bottom: 16, right: 60)
        }
    }

    func configureTextView() {
        guard let note = asset else {
            return
        }
        textView.text = note.text
    }

    func saveOrDiscard() {
        if textView.text.isEmpty {
            discardNote()
        } else {
            saveNote()
        }
    }

    func discardNote() {
        guard let asset = asset else {
            return
        }
        let action = AssetAction.deleteAsset(assetID: asset.uuid)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func saveNote() {
        if let _ = asset {
            updateTextNote()
        } else {
            createTextNote()
        }
    }

    func updateTextNote() {
        guard let asset = asset else {
            return
        }
        let action = AssetAction.updateText(assetID: asset.uuid, text: textView.text)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    func createTextNote() {
        let action = AssetAction.createAssetFor(text: textView.text)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

}

extension TextNoteViewController: UITextViewDelegate {
    // No op for now.
}
