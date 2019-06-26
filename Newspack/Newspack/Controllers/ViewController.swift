import UIKit
import WordPressFlux

class ViewController: UIViewController {

    var receipt: Receipt?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkSession()
    }

    func checkSession() {
        guard SessionManager.shared.state == .initialized else {
            receipt = SessionManager.shared.onChange({
                self.checkSession()
            })
            return
        }

        receipt = nil

        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SiteMenuViewController")
        controller.modalTransitionStyle = .crossDissolve
        navigationController?.setViewControllers([controller], animated: true)
    }

}
