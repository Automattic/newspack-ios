import UIKit
import NewspackFramework

protocol PhotoCellProvider {
    var uuid: UUID! { get }
    var name: String! { get }
    var caption: String! { get }
    var needsManualUpload: Bool { get }
}

class PhotoTableViewCell: ProgressCell {

    static let imageSize = CGSize(width: 32, height: 32)

    @IBOutlet var thumbnail: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var captionLabel: UILabel!
    @IBOutlet var syncButton: UIButton!

    var uuid: UUID?
    var syncCallback: ((UUID) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        Appearance.style(cell: self)
        titleLabel.textColor = .text
        captionLabel.textColor = .text
        Appearance.style(cellSyncButton: syncButton, iconType: .cloudUpload)
        thumbnail.layer.cornerRadius = 8
    }

    @IBAction func handleSyncTapped() {
        guard let uuid = uuid else {
            return
        }
        syncCallback?(uuid)
    }

    func configure(photo: PhotoCellProvider, image: UIImage?, callback: @escaping (UUID) -> Void) {
        uuid = photo.uuid
        thumbnail.image = image
        titleLabel.text = photo.name
        captionLabel.text = photo.caption
        observeProgress(uuid: photo.uuid)
        syncButton.isHidden = !photo.needsManualUpload
        syncCallback = callback
    }

}
