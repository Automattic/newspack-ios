import UIKit

protocol TextNoteCellProvider {
    var text: String! { get }
}

class TextNoteTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var syncButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        titleLabel.textColor = .text
        Appearance.style(cellSyncButton: syncButton, iconType: .cloudUpload)
    }

    @IBAction func handleSyncTapped() {
        print("tapped")
    }

    func configure(note: TextNoteCellProvider) {
        titleLabel?.text = note.text
    }

}
