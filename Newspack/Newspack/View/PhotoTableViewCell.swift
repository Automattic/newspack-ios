import UIKit
import NewspackFramework

protocol PhotoCellProvider {
    var uuid: UUID! { get }
    var name: String! { get }
    var caption: String! { get }
}

class PhotoTableViewCell: ProgressCell {

    static let imageSize = CGSize(width: 32, height: 32)

    @IBOutlet var thumbnail: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var captionLabel: UILabel!
    @IBOutlet var syncButton: UIButton!

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
        print("tapped")
    }

    func configure(photo: PhotoCellProvider, image: UIImage?) {
        thumbnail.image = image
        titleLabel.text = photo.name
        captionLabel.text = photo.caption
        observeProgress(uuid: photo.uuid)
    }

}
