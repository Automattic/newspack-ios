import UIKit

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet var toggle: UISwitch!

    var onChange: ((Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        Appearance.style(cell: self)
    }

    func configureCell(title: String, toggleOn: Bool) {
        toggle.setOn(toggleOn, animated: false)
        textLabel?.text = title
    }

    @IBAction func handleToggleChanged(sender: UISwitch) {
        onChange?(toggle.isOn)
    }

}
