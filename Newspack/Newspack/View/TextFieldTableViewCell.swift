import UIKit
import NewspackFramework

class TextFieldTableViewCell: UITableViewCell {

    @IBOutlet var textField: UITextField!

    var delegate: UITextFieldDelegate? {
        get {
            return textField.delegate
        }
        set {
            textField.delegate = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        textField.font = .tableViewText
        textField.textColor = .text
    }

}
