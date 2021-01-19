import UIKit
import NewspackFramework

protocol TextNoteCellProvider {
    var text: String! { get }
}

class TextNoteTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        titleLabel.textColor = .text
    }

    func configure(note: TextNoteCellProvider) {
        titleLabel?.text = note.text
    }

}
