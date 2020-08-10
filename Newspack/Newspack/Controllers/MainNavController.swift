import Foundation
import UIKit

final class MainNavController: UINavigationController {

    var sessionReceipt: Any?
    var authenticationManager: AuthenticationManager?

    private lazy var menuController: MenuViewController = {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .menu) as! MenuViewController
        controller.restorationClass = MainNavController.self
        controller.restorationIdentifier = MainNavController.menuControllerIdentifier
        return controller
    }()

    private lazy var storyNavigationController: StoryNavigationController = {
        let controller = MainStoryboard.instantiateViewController(withIdentifier: .storyNav) as! StoryNavigationController
        controller.restorationClass = MainNavController.self
        controller.restorationIdentifier = MainNavController.storyNavIdentifier
        return controller
    }()

    private lazy var sidebarContainerController: SidebarContainerViewController = {
        let controller = SidebarContainerViewController(mainViewController: storyNavigationController, sidebarViewController: menuController)
        controller.delegate = self
        controller.view.backgroundColor = .basicBackground
        controller.modalTransitionStyle = .crossDissolve

        controller.restorationClass = MainNavController.self
        controller.restorationIdentifier = MainNavController.sidebarControllerIdentifier

        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Call handleSessionChange initially to create the starting view hierarchy.
        // Important as the intial session is configured before the app has
        // finished launching.
        handleSessionChange()
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

        setViewControllers([sidebarContainerController], animated: true)

        presentedViewController?.dismiss(animated: true, completion: nil)
    }

}

// MARK: - State Restoration

extension MainNavController: UIViewControllerRestoration {
    static let sidebarControllerIdentifier = SidebarContainerViewController.classnameWithoutNamespaces
    static let storyNavIdentifier = StoryNavigationController.classnameWithoutNamespaces
    static let menuControllerIdentifier = MenuViewController.classnameWithoutNamespaces

    static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        guard
            let controller = AppDelegate.shared.window?.rootViewController as? MainNavController,
            let component = identifierComponents.last
        else {
            return nil
        }

        if component == menuControllerIdentifier {
            return controller.menuController
        }

        if component == storyNavIdentifier {
            return controller.storyNavigationController
        }

        if component == sidebarControllerIdentifier {
            return controller.sidebarContainerController
        }

        return controller
    }
}

// MARK: - Session related

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

extension MainNavController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {

        let state = SessionManager.shared.state
        if state == .uninitialized && viewController is InitialViewController {
            authenticationManager = AuthenticationManager()
            authenticationManager?.showAuthenticator(controller: self)
            return
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

// MARK: - SidebarContainer Delegate

extension MainNavController: SidebarContainerDelegate {

    func containerShouldShowSidebar(container: SidebarContainerViewController) -> Bool {
        return true
    }

    func containerWillShowSidebar(container: SidebarContainerViewController) {
        // No op
    }

    func containerDidShowSidebar(container: SidebarContainerViewController) {
        Notification.send(.sidebarOpened)
    }

    func containerWillHideSidebar(container: SidebarContainerViewController) {
        // No op
    }

    func containerDidHideSidebar(container: SidebarContainerViewController) {
        Notification.send(.sidebarClosed)
    }

}

extension Notification.Name {
    static let sidebarOpened = Notification.Name(rawValue: "sidebar_opened")
    static let sidebarClosed = Notification.Name(rawValue: "sidebar_closed")
}
