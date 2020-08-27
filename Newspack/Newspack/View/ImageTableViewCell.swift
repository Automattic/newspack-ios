import UIKit

class ImageTableViewCell: UITableViewCell {

    static let imageHeight = 200

    @IBOutlet var photoView: UIImageView!

    func configureCell(image: UIImage?) {
        photoView.image = image
    }

}
