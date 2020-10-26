import Foundation
import UIKit
import CoreGraphics

protocol SidebarContainerDelegate: AnyObject {
    func containerShouldShowSidebar(container: SidebarContainerViewController) -> Bool
    func containerWillShowSidebar(container: SidebarContainerViewController)
    func containerDidShowSidebar(container: SidebarContainerViewController)
    func containerWillHideSidebar(container: SidebarContainerViewController)
    func containerDidHideSidebar(container: SidebarContainerViewController)
}

class SidebarContainerViewController: UIViewController {

    struct Constants {
        static let alpha1_0 = CGFloat(1)
        static let alpha0_5 = CGFloat(0.5)
        static let alpha0_0 = CGFloat(0)
        static let directionalIdentity = CGFloat(1)
        static let directionalInverted = CGFloat(-1)
        static let sidebarWidth = CGFloat(300)
        static let sidebarAnimationThreshold = CGFloat(0.15)
        static let sidebarAnimationDuration = 0.35
        static let sidebarAnimationDamping = CGFloat(10)
        static let sidebarAnimationInitialVelocity = CGVector(dx: -10, dy: 0)
        static let sidebarAnimationCompletionMin = CGFloat(0.001)
        static let sidebarAnimationCompletionMax = CGFloat(0.999)
        static let sidebarAnimationCompletionFactorFull = CGFloat(1.0)
        static let sidebarAnimationCompletionFactorZero = CGFloat(0.0)
        static let mainControllerEncodeKey = "mainControllerEncodeKey"
        static let sideControllerEncodeKey = "sideControllerEncodeKey"
    }

    private(set) var sidebarViewController: UIViewController
    private(set) var mainViewController: UIViewController
    private(set) var isSidebarVisible = false
    var automaticallyMatchSidebarInsetsWithMainInsets = true
    weak var delegate: SidebarContainerDelegate?

    private var animator: UIViewPropertyAnimator?
    private var isPanningActive = false
    private var touchCaptureView = UIView() // Used to block user interaction while the menu is visible.

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        var recognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(recognizer:)))
        recognizer.numberOfTapsRequired = 1
        recognizer.numberOfTouchesRequired = 1
        return recognizer
    }()

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        var recognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }()

    private var mainView: UIView {
        return mainViewController.view
    }

    private var sidebarView: UIView {
        return sidebarViewController.view
    }

    private var mainChildView: UIView {
        return mainNavigationController?.viewControllers.first?.view ?? mainView
    }

    private var mainNavigationController: UINavigationController? {
        guard let navController = mainViewController as? UINavigationController else {
            return nil
        }
        return navController
    }

    private var mainChildTableView: UITableView? {
        return mainChildView.subviews.first as? UITableView
    }

    private var sideChildTableView: UITableView? {
        return sidebarView.subviews.first as? UITableView
    }

    private var activeViewController: UIViewController {
        return isSidebarVisible ? sidebarViewController : mainViewController
    }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        // We're officially taking over the Appearance Methods sequence, for Child ViewControllers
        return false
    }

    override var shouldAutorotate: Bool {
        return isPanningActive && activeViewController.shouldAutorotate
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private var isRightToLeft: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft
    }

    /// The purpose of this is to normalize calculations, regardless of the writing direction, so that we do not need to duplicate checks.
    ///
    /// Rather than checking:
    ///     `isRTL == false && translation.x < 0` OR `isRTL == true ^^ translation.x > 0`,
    ///
    /// We can simply check for:
    ///     `translation.x * directionalMultiplier < 0`.
    ///
    private var directionalMultiplier: CGFloat {
        return isRightToLeft ? Constants.directionalInverted : Constants.directionalIdentity
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init(mainViewController: UIViewController, sidebarViewController: UIViewController) {
        self.mainViewController = mainViewController
        self.sidebarViewController = sidebarViewController

        super.init(nibName: nil, bundle: nil)

        addChild(mainViewController)
        addChild(sidebarViewController)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(panGestureRecognizer)

        // The following order is important. The mainView should be lowest.
        // The capture view should be second so it covers the main view.
        // The sidebar view should be topmost.
        view.addSubview(mainView)
        attachCaptureView()
        attachSidebarView()

        mainViewController.didMove(toParent: self)
        sidebarViewController.didMove(toParent: self)

        NotificationCenter.default.addObserver(self, selector: #selector(handleToggleSidebarNotification(notification:)), name: .toggleSidebarNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainViewController.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mainViewController.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainViewController.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainViewController.endAppearanceTransition()
    }

    func attachSidebarView() {
        var sidebarFrame = view.bounds
        sidebarFrame.origin.x = isRightToLeft ? sidebarFrame.size.width : -Constants.sidebarWidth
        sidebarFrame.size.width = Constants.sidebarWidth

        sidebarView.frame = sidebarFrame
        sidebarView.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]

        view.insertSubview(sidebarView, aboveSubview: touchCaptureView)
    }

    func attachCaptureView() {
        touchCaptureView.frame = view.bounds
        touchCaptureView.autoresizingMask = view.autoresizingMask
        touchCaptureView.backgroundColor = .systemBackground
        touchCaptureView.alpha = Constants.alpha0_0
        touchCaptureView.isUserInteractionEnabled = true
        touchCaptureView.addGestureRecognizer(tapGestureRecognizer)

        view.insertSubview(touchCaptureView, aboveSubview: mainView)
    }

    @objc
    func handleToggleSidebarNotification(notification: Notification) {
        toggleSidebar()
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(mainViewController, forKey: Constants.mainControllerEncodeKey)
        coder.encode(sidebarViewController, forKey: Constants.sideControllerEncodeKey)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SidebarContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else {
            return true
        }

        let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)

        // Scenario A: It's a Vertical Swipe
        if abs(translation.x) < abs(translation.y) {
            return false
        }

        // Scenario B: Sidebar is NOT visible, and we got a Left Swipe (OR) Sidebar is Visible and we got a Right Swipe
        let normalizedTranslation = translation.x * directionalMultiplier
        if !isSidebarVisible && normalizedTranslation < 0 || isSidebarVisible && normalizedTranslation > 0 {
            return false
        }

        // Scenario C: Sidebar or Main are being dragged
        if mainChildTableView?.isDragging == true || sideChildTableView?.isDragging == true {
            return false
        }

        // Scenario D: Sidebar is not visible, but there are multiple viewControllers in its hierarchy
        if let count = mainNavigationController?.viewControllers.count, !isSidebarVisible, count > 1 {
            return false
        }

        // Scenario E: Sidebar is not visible, but the delegate says NO, NO!
        if let delegate = delegate, !isSidebarVisible, delegate.containerShouldShowSidebar(container: self) {
            return false
        }

        // Scenario F: Sidebar is visible and is being edited
        if isSidebarVisible && sidebarViewController.isEditing {
            return false
        }

        if isPanningActive {
            return false
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Why is this needed: UITableView's swipe gestures might require our Pan gesture to fail. Capisci?
        guard gestureRecognizer == panGestureRecognizer else {
            return true
        }
        return isPanningActive
    }
}

// MARK: - Gesture Recognizer Callbacks
extension SidebarContainerViewController {
    @objc func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
        if isPanningActive {
            return
        }
        hideSidebar(animated: true)
    }

    @objc func panGestureRecognized(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.began {
            beginPanning()

        } else if recognizer.state == UIGestureRecognizer.State.ended ||
            recognizer.state == UIGestureRecognizer.State.cancelled ||
            recognizer.state == UIGestureRecognizer.State.failed {
            finishPanning()

        } else {
            continuePanning(recognizer: recognizer)
        }
    }
}

// MARK: - Panning and Animation Related
extension SidebarContainerViewController {
    /// The following method will (attempt) to match the Sidebar's TableViewInsets with the MainView's SafeAreaInsets.
    /// Ideally, the first Sidebar row will be aligned against the SearchBar on its right hand side.
    ///
    func ensureSideTableViewInsetsMatchMainViewInsets() {
        guard let sideTableView = sideChildTableView, !automaticallyMatchSidebarInsetsWithMainInsets else {
            return
        }

        let mainSafeInsets = mainChildView.safeAreaInsets
        var contentInset = sideTableView.contentInset

        // Content Insets
        contentInset.top = mainSafeInsets.top
        contentInset.bottom = mainSafeInsets.bottom

        guard sideTableView.contentInset != contentInset else {
            return
        }
        sideTableView.contentInset = contentInset

        // Scroll Insets
        var scrollIndicatorInsets = sideTableView.verticalScrollIndicatorInsets
        scrollIndicatorInsets.top = mainSafeInsets.top
        sideTableView.verticalScrollIndicatorInsets = scrollIndicatorInsets

        // Reposition
        sideTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: false)
    }

    func animatorForSidebarVisibility(visible: Bool) -> UIViewPropertyAnimator {
        let x = Constants.sidebarWidth * directionalMultiplier
        let transform: CGAffineTransform = visible ? CGAffineTransform(translationX: x, y: 0) : .identity
        let alphaSidebar: CGFloat = visible ? Constants.alpha1_0 : Constants.alpha0_0
        let alphaCapture: CGFloat = visible ? Constants.alpha0_5 : Constants.alpha0_0

        let parameters = UISpringTimingParameters(dampingRatio: Constants.sidebarAnimationDamping, initialVelocity: Constants.sidebarAnimationInitialVelocity)

        let animator = UIViewPropertyAnimator(duration: Constants.sidebarAnimationDuration, timingParameters: parameters)
        animator.addAnimations {
            self.touchCaptureView.alpha = alphaCapture
            self.mainView.transform = transform
            self.sidebarView.transform = transform
            self.touchCaptureView.transform = transform
            self.sidebarView.alpha = alphaSidebar
        }
        return animator
    }

    private func beginPanning() {
        isPanningActive = true
        let newVisibility = !isSidebarVisible
        animator = animatorForSidebarVisibility(visible: newVisibility)
        beginSidebarTransition(appearing: newVisibility)
    }

    private func continuePanning(recognizer: UIPanGestureRecognizer) {
        guard let animator = animator else {
            return
        }
        let translation = recognizer.translation(in: mainView)
        let translationMultiplier: CGFloat = isSidebarVisible ? -1 : 1

        let progress = translation.x / Constants.sidebarWidth * translationMultiplier * directionalMultiplier

        animator.fractionComplete = max(Constants.sidebarAnimationCompletionMin, min(Constants.sidebarAnimationCompletionMax, progress))
    }

    private func finishPanning() {
        guard let animator = animator else {
            return
        }
        if animator.fractionComplete < Constants.sidebarAnimationThreshold {
            animator.isReversed = true
            beginSidebarTransition(appearing: isSidebarVisible)
        } else {
            isSidebarVisible = !isSidebarVisible
        }

        let didBecomeVisible = isSidebarVisible
        animator.addCompletion { [weak self] (finalPosition) in
            self?.isPanningActive = false
            self?.endSidebarTransition(appeared: didBecomeVisible)
            UIViewController.attemptRotationToDeviceOrientation()
        }

        animator.continueAnimation(withTimingParameters: nil, durationFactor: Constants.sidebarAnimationCompletionFactorFull)
    }

    func beginSidebarTransition(appearing: Bool) {
        if appearing {
            delegate?.containerWillShowSidebar(container: self)
            ensureSideTableViewInsetsMatchMainViewInsets()
        } else {
            delegate?.containerWillHideSidebar(container: self)
        }
        sidebarViewController.beginAppearanceTransition(appearing, animated: true)
    }

    func endSidebarTransition(appeared: Bool) {
        if appeared {
            delegate?.containerDidShowSidebar(container: self)
        } else {
            delegate?.containerDidHideSidebar(container: self)
        }
        sidebarViewController.endAppearanceTransition()
    }
}

// MARK: - Public API
extension SidebarContainerViewController {
    func toggleSidebar() {
        if isSidebarVisible {
            hideSidebar(animated: true)
        } else {
            showSidebar()
        }
    }

    func showSidebar() {
        if isPanningActive || isSidebarVisible {
            return
        }

        beginSidebarTransition(appearing: true)

        let animator = animatorForSidebarVisibility(visible: true)
        animator.addCompletion { (finalPosition) in
            self.isSidebarVisible = true
            self.endSidebarTransition(appeared: true)
        }

        animator.startAnimation()
        self.animator = animator
    }

    func hideSidebar(animated: Bool) {
        if isPanningActive || !isSidebarVisible {
            return
        }
        beginSidebarTransition(appearing: false)
        let animator = animatorForSidebarVisibility(visible: false)
        animator.addCompletion { (finalPosition) in
            self.isSidebarVisible = false
            self.endSidebarTransition(appeared: false)
            UIViewController.attemptRotationToDeviceOrientation()
        }

        if animated {
            animator.startAnimation()
        } else {
            animator.fractionComplete = Constants.sidebarAnimationCompletionFactorFull
            animator.continueAnimation(withTimingParameters: nil, durationFactor: Constants.sidebarAnimationCompletionFactorZero)
        }

        self.animator = animator
    }

    func requirePanningToFail() {
        /// Force the panGestureRecognizer recognizer to fail. Seen in WWDC 2014 (somewhere), and a better way is yet to be found.
        ///
        panGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = true
    }
}

extension Notification.Name {
    static let toggleSidebarNotification = Notification.Name("toggleSidebarNotification")
}
