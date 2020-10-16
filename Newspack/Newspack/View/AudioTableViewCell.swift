import UIKit

protocol AudioCellProvider {
    var uuid: UUID! { get }
    var name: String! { get }
    var caption: String! { get }
}

class AudioTableViewCell: ProgressCell {

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
    }

    @IBAction func handleSyncTapped() {
        print("tapped")
    }

    func configure(audio: AudioCellProvider) {
        titleLabel.text = audio.name
        captionLabel.text = audio.caption
        observeProgress(uuid: audio.uuid)
    }

}
