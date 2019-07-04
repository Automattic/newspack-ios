import Foundation
import UIKit

class FadeTransitionController: NSObject, UIViewControllerAnimatedTransitioning {
    let timeInterval: TimeInterval = 0.3
    let hideNavigationBar: Bool

    init(hideNavigationBar: Bool) {
        self.hideNavigationBar = hideNavigationBar
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return timeInterval
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: .to) else {
            return
        }

        toController.view.alpha = 0.0
        transitionContext.containerView.addSubview(toController.view)

        UIView.animate(withDuration: timeInterval, animations: {

            toController.view.alpha = 1.0
            toController.navigationController?.setNavigationBarHidden(self.hideNavigationBar, animated: false)

        }, completion: { finished in

            transitionContext.completeTransition(finished)

        })

    }
}
