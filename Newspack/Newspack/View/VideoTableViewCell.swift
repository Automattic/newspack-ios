import UIKit

protocol VideoCellProvider {
    var uuid: UUID! { get }
    var name: String! { get }
    var caption: String! { get }
    var needsManualUpload: Bool { get }
}

class VideoTableViewCell: ProgressCell {

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

    func configure(video: VideoCellProvider, image: UIImage?, callback: @escaping (UUID) -> Void) {
        uuid = video.uuid
        thumbnail.image = image
        titleLabel.text = video.name
        captionLabel.text = video.caption
        observeProgress(uuid: video.uuid)
        syncButton.isHidden = !video.needsManualUpload
        syncCallback = callback
    }

}
