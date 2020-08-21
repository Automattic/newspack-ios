import UIKit

class TextViewTableViewCell: UITableViewCell {

    @IBOutlet var textView: UITextView!

    var delegate: UITextViewDelegate? {
        get {
            return textView.delegate
        }
        set {
            textView.delegate = newValue
        }
    }

}
