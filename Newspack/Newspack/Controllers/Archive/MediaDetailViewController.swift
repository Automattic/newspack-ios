import Foundation
import UIKit
import AlamofireImage

class MediaDetailViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    var previewURL: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPreview()
    }

    func loadPreview() {
        guard
            let path = previewURL,
            let url = URL(string: path)
        else {
            return
        }
        imageView.downloadImage(from: url)
    }
}
