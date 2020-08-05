import Foundation
import Gridicons
import WPMediaPicker

/// The ToolbarViewController encapsulates common functionality around toolbar
/// behaviors between the FoldersViewController and AssetsViewController.
/// If protocol extensions can ever support declaring default @objc methods the
/// functionality in this class could be refactored to a protocol extension that
/// decoreates the Folders and Assets view controllers rather than providing a
/// parent class. A protocol extension would need @objc methods to provide a default
/// implementation for WPMediaPickerViewControllerDelegate methods.
///
class ToolbarViewController: UIViewController {

    @IBOutlet var textNoteButton: UIBarButtonItem!
    @IBOutlet var photoButton: UIBarButtonItem!
    @IBOutlet var cameraButton: UIBarButtonItem!
    @IBOutlet var audioNoteButton: UIBarButtonItem!

    // Storage for a capture controller while it is needed.
    var captureController: MediaCaptureController?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureToolbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    func configureToolbar() {
        textNoteButton.image = .gridicon(.posts)
        photoButton.image = .gridicon(.imageMultiple)
        cameraButton.image = .gridicon(.camera)
        audioNoteButton.image = .gridicon(.microphone)
    }

}

// MARK: - Actions

extension ToolbarViewController {

    @IBAction func handleTextNoteButton(sender: UIBarButtonItem) {
        // Temporary action just for testing.
        let action = AssetAction.createAssetFor(text: "New Text Note")
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

    @IBAction func handlePhotoButton(sender: UIBarButtonItem) {
        let picker = MediaPickerViewController()
        navigationController?.present(picker, animated: true, completion: nil)
    }

    @IBAction func handleCameraButton(sender: UIBarButtonItem) {
        guard MediaCaptureController.isCaptureAvailable() else {
            // TODO: Show alert that the camera is not available.
            return
        }

        captureController = MediaCaptureController(presenting: self, onComplete: { [weak self] in
            self?.captureController = nil
        })
        captureController?.presentCapture()
    }

    @IBAction func handleAudioNoteButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

}
