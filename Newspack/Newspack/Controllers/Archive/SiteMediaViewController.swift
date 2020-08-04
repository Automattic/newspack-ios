import UIKit
import WPMediaPicker

class SiteMediaViewController: WPMediaPickerViewController {

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
        super.init(options: SiteMediaViewController.pickerOptions())

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

        configureRightBarButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaDataSource.syncIfNeeded()
    }

    func configureRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddTapped(sender:)))
    }

    @objc func handleAddTapped(sender: UIBarButtonItem) {
        let controller = PhotoLibraryViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    func handleSelectedMediaAsset(asset: MediaAsset) {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .mediaDetail) as! MediaDetailViewController
        controller.previewURL = asset.sourceURL
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension SiteMediaViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard let asset = assets.first as? MediaAsset else {
            return
        }
        picker.clearSelectedAssets(false)

        handleSelectedMediaAsset(asset: asset)
    }

}
