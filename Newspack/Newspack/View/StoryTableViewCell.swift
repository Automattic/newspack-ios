import UIKit

class StoryTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var syncImage: UIImageView!
    @IBOutlet var iconView: UIStackView!
    @IBOutlet var textIcon: UIButton!
    @IBOutlet var photosIcon: UIButton!
    @IBOutlet var videoIcon: UIButton!
    @IBOutlet var audioIcon: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func applyStyles() {

    }

    func configure() {

    }

}
