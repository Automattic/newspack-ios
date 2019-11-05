import Foundation
import WPMediaPicker

class PhotoLibraryViewController: WPMediaPickerViewController {
    let mediaDataSource = WPPHAssetDataSource()

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
        super.init(options: PhotoLibraryViewController.pickerOptions())

        self.mediaPickerDelegate = self
        self.dataSource = self.mediaDataSource
        self.selectionActionTitle = NSLocalizedString("Insert", comment:"Verb. Inserts selected photos into a post.")
        navigationItem.title = NSLocalizedString("Photos", comment: "Noun. Title of a screen that shows a device's photo library.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        collectionView?.backgroundView = nil
        collectionView?.backgroundColor = .white
    }
}

extension PhotoLibraryViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        print("picked")
    }

}
