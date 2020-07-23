import Foundation

/// EventMonitor provides a proxy mechanism for analytics tracking.
/// Significant events may be dispatched via NSNotifications vs some custom type
/// and will be picked up by the EventMonitor. A lightweight extenion to Notification
/// provides a convenience method for dispatching notifications that the monitor
/// will detect.
///
class EventMonitor: NSObject {

    static let shared = EventMonitor()

    fileprivate var object: AnyObject? {
        didSet {
            if let _ = oldValue {
                NotificationCenter.default.removeObserver(self)
            }
            if let _ = object {
                NotificationCenter.default.addObserver(self, selector: #selector(handle(notification:)), name: nil, object: object)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handle(notification:)), name: nil, object: self)
    }

    /// Register an object in order to subscribe to its notifiations. This must
    /// be called to begin listening.  Passing nil will stop observing notifications.
    ///
    /// - Parameter object: The object to observe.
    ///
    func registerObject(object: AnyObject?) {
        self.object = object
    }

    /// Handles notifications referencing the subscribed object.
    ///
    /// - Parameter notification: The notification.
    ///
    @objc private func handle(notification: Notification) {
        // For now just log the notification name. When we're ready to wire up
        // analytics we'll revisit.
        LogInfo(message: notification.name.rawValue)
    }

}

/// A lightweight extension providing a convenience method to dispatch notifications
/// that the EventMonitor will handle.
///
extension Notification {

    /// Dispatch a notification for the specific type, and optional userInfo
    /// dictionary that will be detected by the EventMonitor.
    ///
    /// - Parameters:
    ///   - name: The Notification.Name to dispatch.
    ///   - info: An optional userInfo dictionary.
    ///
    static func send(_ name: Notification.Name, info: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: EventMonitor.shared.object, userInfo: info)
    }

}
