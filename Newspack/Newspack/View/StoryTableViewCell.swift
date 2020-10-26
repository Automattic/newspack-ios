import UIKit
import Gridicons
import NewspackFramework

/// A convenience potocol to avoid tightly coupling the StoryFolder model to the
/// cell. Any object implementing the protocol can be a provider.
///
protocol StoryCellProvider {
    var postID: Int64 { get }
    var name: String! { get }
    var textNoteCount: Int { get }
    var imageCount: Int { get }
    var videoCount: Int { get }
    var audioNoteCount: Int { get }
}


class StoryTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var iconView: UIStackView!
    // Note: Using buttons for convenience since they contain an image and a label.
    // User interaction should be disabled in the xib.
    @IBOutlet var textIcon: UIButton!
    @IBOutlet var photosIcon: UIButton!
    @IBOutlet var videoIcon: UIButton!
    @IBOutlet var audioIcon: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        Appearance.style(cellIconButton: textIcon, iconType: .posts)
        Appearance.style(cellIconButton: photosIcon, iconType: .imageMultiple)
        Appearance.style(cellIconButton: videoIcon, iconType: .video)
        Appearance.style(cellIconButton: audioIcon, iconType: .microphone)
    }

    /// Configure the cell for the story provider.
    ///
    /// - Parameters:
    ///   - story: A StoryCellProvider instance.
    ///   - current: Whether this cell represents the currently selected story.
    ///
    func configure(story: StoryCellProvider, current: Bool) {
        // Configure title.
        titleLabel.text = story.name
        titleLabel.textColor = current ? .textLink : .text

        // Configure which icons are visible (if any)
        textIcon.isHidden = story.textNoteCount == 0
        textIcon.setTitle(String(story.textNoteCount), for: .normal)

        photosIcon.isHidden = story.imageCount == 0
        photosIcon.setTitle(String(story.imageCount), for: .normal)

        videoIcon.isHidden = story.videoCount == 0
        videoIcon.setTitle(String(story.videoCount), for: .normal)

        audioIcon.isHidden = story.audioNoteCount == 0
        audioIcon.setTitle(String(story.audioNoteCount), for: .normal)

        // Hide or show the icon view
        iconView.isHidden = (textIcon.isHidden && photosIcon.isHidden && videoIcon.isHidden && audioIcon.isHidden)
    }

}
