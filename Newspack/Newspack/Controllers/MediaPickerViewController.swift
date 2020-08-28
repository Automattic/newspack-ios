import Foundation
import UIKit
import WPMediaPicker
import NewspackFramework

/// A convenience class for handling some WPNavigationMediaPickerViewController
/// configuration and boiler-plate.
///
class MediaPickerViewController: WPNavigationMediaPickerViewController {

    fileprivate var delegateHelper: MediaPickerDelegateHelper?

    /// Designated initalizer. Takes care of the desired config.
    ///
    init() {
        let options = WPMediaPickerOptions()
        options.allowCaptureOfMedia = false

        super.init(options: options)
        delegateHelper = MediaPickerDelegateHelper(controller: self)
        delegate = delegateHelper
        dataSource = WPPHAssetDataSource.sharedInstance()
        selectionActionTitle = NSLocalizedString("Select", comment: "Verb. Title of a control that selects a set of images.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()
    }

    func configureStyle() {
        UICollectionView.appearance(whenContainedInInstancesOf: [WPNavigationMediaPickerViewController.self]).backgroundColor = .systemBackground
    }
}

/// This is a little weird. We want to encapsulate all the WPNavigationMediaPickerViewController
/// related things, but it can not be its own delegate. It already implements the
/// WPMediaPickerViewControllerDelegate protocol so making its own delegate creates
/// a self-referencing loop when calling delegate methods.  To get around this
/// and still encapsulate all the logic in one place we'll use a private
/// helper class to act as a delegate.
///
fileprivate class MediaPickerDelegateHelper: NSObject {

    // Could be unowned but opting for weak for safety and nullability.
    weak var controller: UIViewController?

    init(controller: UIViewController) {
        self.controller = controller
    }

    func processSelectedAssets(assets: [WPMediaAsset]) {
        guard let assets = assets as? [PHAsset] else {
            // This cast should never fail, but log it just in case.
            LogError(message: "Unable to cast WPMediaAssets to PHAssets")
            return
        }

        let action = AssetAction.importMedia(assets: assets)
        SessionManager.shared.sessionDispatcher.dispatch(action)
    }

}

// MARK: - Delegate methods

extension MediaPickerDelegateHelper: WPMediaPickerViewControllerDelegate {

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        processSelectedAssets(assets: assets)
        controller?.dismiss(animated: true, completion: nil)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        controller?.dismiss(animated: true, completion: nil)
    }

}
