import Foundation
import Gutenberg
import WPMediaPicker

class SiteMediaSelectViewController: SiteMediaViewController {

    let editorCallback: MediaPickerDidPickMediaCallback

    init(callback: @escaping MediaPickerDidPickMediaCallback) {
        editorCallback = callback
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureRightBarButton() {
        //no op.
    }

    override func handleSelectedMediaAsset(asset: MediaAsset) {
        let mediaInfo = MediaInfo(id: asset.mediaID, url: asset.sourceURL, type: "image")
        editorCallback([mediaInfo])

        navigationController?.popViewController(animated: true)
    }

}
