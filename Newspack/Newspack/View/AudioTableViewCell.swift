import UIKit

protocol AudioCellProvider {
    var uuid: UUID! { get }
    var name: String! { get }
    var caption: String! { get }
    var needsManualUpload: Bool { get }
}

class AudioTableViewCell: ProgressCell {

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
    }

    @IBAction func handleSyncTapped() {
        guard let uuid = uuid else {
            return
        }
        syncCallback?(uuid)
    }

    func configure(audio: AudioCellProvider, callback: @escaping (UUID) -> Void) {
        uuid = audio.uuid
        titleLabel.text = audio.name
        captionLabel.text = audio.caption
        observeProgress(uuid: audio.uuid)
        syncButton.isHidden = !audio.needsManualUpload
        syncCallback = callback
    }

}
