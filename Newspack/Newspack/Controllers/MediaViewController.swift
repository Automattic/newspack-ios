import UIKit
import WPMediaPicker

class MediaViewController: WPMediaPickerViewController {

    let mediaDataSource = SiteMediaDataSource()

    override init(options: WPMediaPickerOptions) {
        super.init(options: options)

        self.mediaPickerDelegate = self
        self.dataSource = mediaDataSource
        self.selectionActionTitle = NSLocalizedString("Insert", comment:"Verb. Inserts selected photos into a post.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncIfNeeded()
    }

    func syncIfNeeded() {
        let dispatcher = SessionManager.shared.sessionDispatcher
        dispatcher.dispatch(MediaAction.syncItems)
    }

}

extension MediaViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {

    }
}
