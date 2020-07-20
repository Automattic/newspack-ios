import Foundation
import UIKit

final class MainNavController: UINavigationController {

    var sessionReceipt: Any?
    var authenticationManager: AuthenticationManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForSessionChanges()
        delegate = self
    }

    /// Show's the initital view controller if it is not already in the nav stack
    ///
    func showInitialController() {
        if viewControllers.first is InitialViewController {
            return
        }

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .initial)
        var controllers = viewControllers
        controllers.insert(controller, at: 0)
        setViewControllers(controllers, animated: false)
    }

    func showSidebarController() {
        guard viewControllers.first is InitialViewController else {
            return
        }

        let menuController = MainStoryboard.instantiateViewController(withIdentifier: .menu)
        let folderController = MainStoryboard.instantiateViewController(withIdentifier: .folderList)
        let navController = UINavigationController(rootViewController: folderController)

        let controller = SidebarContainerViewController(mainViewController: navController, sidebarViewController: menuController)
        controller.modalTransitionStyle = .crossDissolve
        setViewControllers([controller], animated: true)

        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}


// Session related
//
extension MainNavController {

    func listenForSessionChanges() {
        guard sessionReceipt == nil else {
            return
        }

        sessionReceipt = SessionManager.shared.onChange {
            self.handleSessionChange()
        }
    }

    func handleSessionChange() {
        let sessionState = SessionManager.shared.state
        if sessionState == .uninitialized {
            handleUnauthenticatedSession()

        } else if sessionState == .initialized {
            handleAuthenticatedSession()

        }

        popToRootViewController(animated: true)
    }

    func handleAuthenticatedSession() {
        showSidebarController()
    }

    func handleUnauthenticatedSession() {
        showInitialController()
    }

}


// MARK: - Nav Delegate Related
//
extension MainNavController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {

        let state = SessionManager.shared.state
        if state == .uninitialized && viewController is InitialViewController {
            authenticationManager = AuthenticationManager()
            authenticationManager?.showAuthenticator(controller: self)
        }

        if state == .initialized {
            authenticationManager = nil
        }
    }

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        guard fromVC is InitialViewController || toVC is InitialViewController else {
            return nil
        }
        return FadeTransitionController(hideNavigationBar: toVC is InitialViewController)
    }

}
