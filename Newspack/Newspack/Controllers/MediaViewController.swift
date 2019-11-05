import UIKit
import WPMediaPicker

class MediaViewController: WPMediaPickerViewController {

    let mediaDataSource = SiteMediaDataSource()

    private class func pickerOptions() -> WPMediaPickerOptions {
        let options = WPMediaPickerOptions()
        options.allowCaptureOfMedia = false
        options.allowMultipleSelection = false
        options.filter = [.image]
        options.preferFrontCamera = false
        options.showActionBar = false
        options.showMostRecentFirst = true
        options.showSearchBar = false
        return options
    }

    init() {
        super.init(options: MediaViewController.pickerOptions())

        self.mediaPickerDelegate = self
        self.dataSource = mediaDataSource
        self.selectionActionTitle = NSLocalizedString("Insert", comment:"Verb. Inserts selected photos into a post.")
        navigationItem.title = NSLocalizedString("Media", comment: "Noun. Title of a screen that shows a site's media library.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        collectionView?.backgroundView = nil
        collectionView?.backgroundColor = .white

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddTapped(sender:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncIfNeeded()
    }

    func syncIfNeeded() {
        let dispatcher = SessionManager.shared.sessionDispatcher
        dispatcher.dispatch(MediaAction.syncItems)
    }

    @objc func handleAddTapped(sender: UIBarButtonItem) {
        let controller = PhotoLibraryViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension MediaViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard let asset = assets.first as? MediaAsset else {
            return
        }
        picker.clearSelectedAssets(false)

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .mediaDetail) as! MediaDetailViewController
        controller.previewURL = asset.sourceURL
        navigationController?.pushViewController(controller, animated: true)
    }

}
