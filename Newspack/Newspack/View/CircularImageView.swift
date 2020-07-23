import UIKit

/// Makes a UIImageView circular. Handy for gravatars
///
class CircularImageView: UIImageView {

    convenience init() {
        self.init(frame: CGRect.zero)
        layer.masksToBounds = true
    }

    override var frame: CGRect {
        didSet {
            refreshRadius()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshRadius()
    }

    fileprivate func refreshRadius() {
        let radius = frame.width * 0.5
        if layer.cornerRadius != radius {
            layer.cornerRadius = radius
        }
    }

}
