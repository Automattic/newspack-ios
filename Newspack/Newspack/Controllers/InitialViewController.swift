import UIKit

class InitialViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkSession()
    }

    func checkSession() {
        let state = SessionManager.shared.state

        if state == .initialized {
            navigateToMenu()
        } else if state == .uninitialized {
            presentAuthenticator()
        }

    }

    func presentAuthenticator() {
        guard
            let navController = navigationController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {
            return
        }

        appDelegate.authenticationManager.showAuthenticator(controller: navController)
    }

    func navigateToMenu() {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SiteMenuViewController")
        controller.modalTransitionStyle = .crossDissolve
        navigationController?.setViewControllers([controller], animated: true)
    }
}
