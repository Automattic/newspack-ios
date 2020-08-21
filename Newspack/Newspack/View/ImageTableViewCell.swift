import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet var photoView: UIImageView!

    func configureCell(image: UIImage?) {
        photoView.image = image
    }

}
