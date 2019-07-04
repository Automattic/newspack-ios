import UIKit

class InitialViewController: UIViewController {

    lazy var authenticationManager = AuthenticationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        guard let navController = parent as? UINavigationController else {
            return
        }

        navController.delegate = self
    }

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
        guard let navController = navigationController else {
            return
        }

        authenticationManager.showAuthenticator(controller: navController)
    }

    func navigateToMenu() {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SiteMenuViewController")
        controller.modalTransitionStyle = .crossDissolve
        navigationController?.setViewControllers([controller], animated: true)
    }
}

extension InitialViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let hideBar = toVC is InitialViewController
        return FadeTransitionController(hideNavigationBar: hideBar)
    }
}
