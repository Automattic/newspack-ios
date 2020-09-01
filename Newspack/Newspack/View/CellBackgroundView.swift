import Foundation
import UIKit
import NewspackFramework

// Apparently views used for a cell's background do not have their traits updated
// correctly. So we'll use this class to inspect the parent's traits to see if
// we're in light or dark mode.
class CellBackgroundView: UIView {

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let superView = newSuperview else {
            return
        }
        if superView.traitCollection.userInterfaceStyle == .dark {
            backgroundColor = .withColorStudio(.newspackBlue, shade: .shade80)
        } else {
            backgroundColor = .withColorStudio(.newspackBlue, shade: .shade20)
        }
    }

}
