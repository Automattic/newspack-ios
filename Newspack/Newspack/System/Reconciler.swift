import Foundation
import UIKit

/// Responsible for resolving any differences between what is currently in the
/// file system with what is currently stored in core data.
///
class Reconciler {

    var sessionReceipt: Any?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init() {
        listenForSessionChanges()
        listenForNotifications()
    }

    /// Tells the reconciler to check for inconsistencies between the file system
    /// and what is stored in core data.  If any are found they will be reconciled.
    ///
    func process() {
        guard hasInitializedSession() else {
            return
        }

        guard detect() else {
            return
        }

        reconcile()
    }

    /// Checks for inconsistencies between the file system and what is stored in
    /// core data.
    ///
    /// - Returns: Returns true if any inconsistencies are found. False otherwise.
    ///
    func detect() -> Bool {
        // Check site


        // Check story folders


        // TODO: check story folder contents


        return false
    }

    /// Reconciles any inconsistencies between the file system and what is stored
    /// in core data.
    ///
    func reconcile() {
        // reconcile site
        // if recreated we can bail


        // Check story folders
        // if any are recreated we can bail on their contents.


        // TODO: check folder contents
    }

}


// Notification related
//
extension Reconciler {

    /// Listen for system notifications that would tell us we might need to
    /// reconcile the file system and core data.
    /// Note that .didBecomeActiveNotification is dispatched more often than
    /// .willEnterForgroundNotification. If reconciliation is too frequent or
    /// aggressive we can try switching notifications.
    ///
    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    func handleDidBecomeActive(notification: Notification) {
        process()
    }

}


// Session related
//
extension Reconciler {

    func hasInitializedSession() -> Bool {
        let sessionState = SessionManager.shared.state
        return sessionState == .initialized
    }

    func listenForSessionChanges() {
        guard sessionReceipt == nil else {
            return
        }

        sessionReceipt = SessionManager.shared.onChange {
            self.handleSessionChange()
        }
    }

    func handleSessionChange() {
        process()
    }

}
