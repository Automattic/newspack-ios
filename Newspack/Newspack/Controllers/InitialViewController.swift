import UIKit

/// A view controller to facilitate transitioning from the launch screen to
/// the app proper. Aids in presenting the authentication flow.
///
class InitialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.style(view: view)
    }

}
