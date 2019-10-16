import UIKit
import WPMediaPicker

class MediaViewController: WPMediaPickerViewController {

    override init(options: WPMediaPickerOptions) {
        super.init(options: options)

        self.mediaPickerDelegate = self
        self.dataSource = WPPHAssetDataSource.sharedInstance()
        self.selectionActionTitle = NSLocalizedString("Insert", comment:"Verb. Inserts selected photos into a post.")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension MediaViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {

    }
}
