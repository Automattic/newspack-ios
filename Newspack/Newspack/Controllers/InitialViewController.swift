import UIKit

/// A view controller to facilitate transitioning from the launch screen to
/// the app proper. Aids in presenting the authentication flow.
///
class InitialViewController: UIViewController {

    lazy var authenticationManager = AuthenticationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Required during app launch to set up the custom transition.
        navigationController?.delegate = self
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        guard let navController = parent as? UINavigationController else {
            return
        }

        // Required when returning to the initial view controller
        // in order to set up the custom transition.
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
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .siteMenu)
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
