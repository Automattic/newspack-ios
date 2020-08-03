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
        LogDebug(message: "tapped \(sender.description)")

        // Configure media picker for photos.
        let options = WPMediaPickerOptions()
        let picker = WPNavigationMediaPickerViewController(options: options)
        picker.delegate = self
        picker.dataSource = WPPHAssetDataSource.sharedInstance()
        picker.selectionActionTitle = NSLocalizedString("Select", comment: "Verb. Title of a control that selects a set of images.")
        picker.modalPresentationStyle = .popover
        let controller = picker.popoverPresentationController
        controller?.barButtonItem = sender

        navigationController?.present(picker, animated: true, completion: nil)
    }

    @IBAction func handleCameraButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")

        guard WPMediaCapturePresenter.isCaptureAvailable() else {
            // TODO: Show alert that the camera is not available.
            return
        }

        // Configure media picker for camera.
        let presenter = WPMediaCapturePresenter(presenting: self)
        presenter.mediaType = [.image, .video]
        presenter.completionBlock = { media in
            guard let media = media else {
                return
            }
            print(media.description)
        }

        presenter.presentCapture()
    }

    @IBAction func handleAudioNoteButton(sender: UIBarButtonItem) {
        LogDebug(message: "tapped \(sender.description)")
    }

}

// MARK: - MediaPicker related

extension ToolbarViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        print(assets.description)
    }
}

