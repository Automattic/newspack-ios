import Foundation
import UIKit

/// A simple class to wrap a UUID.  UUIDs are structs and we want value object
/// to use with notifications. Hence this helper class.
///
class ProgressKey {
    let uuid: UUID
    init(uuid: UUID) {
        self.uuid = uuid
    }
}

/// Storage for UIProgress instances associated with a particular StoryAsset.
/// Association is by UUID.  Interested observers should first get a ProgressKey
/// for the UUID in question, then observe notifiations for that ProgressKey.
///
class ProgressStore {

    private var store = [UUID: Progress]()
    private var progressKeys = [UUID: ProgressKey]()

    /// Get a progress object for the specified UUID if it exists.
    ///
    /// - Parameter uuid: A UUID.
    /// - Returns: A Progress instance or nil.
    ///
    func progress(for uuid: UUID) -> Progress? {
        return store[uuid]
    }

    /// Add a Progress instance to the store for the specified UUID. This removes
    /// an existing Progress instance from the store.
    ///
    /// - Parameters:
    ///   - progress: A Progress instance.
    ///   - uuid: The UUID.
    ///
    func add(progress: Progress, for uuid: UUID) {
        remove(for: uuid) // remove stale progress if it exists.
        store[uuid] = progress

        let key = keyForUUID(uuid: uuid)
        notify(key: key, added: true)
    }

    /// Removes the Progress instance for the specified UUID.
    ///
    /// - Parameter uuid: The UUID.
    ///
    func remove(for uuid: UUID) {
        guard let _ = store.removeValue(forKey: uuid) else {
            return
        }

        // Get a reference to the key before removing it.
        let key = keyForUUID(uuid: uuid)
        progressKeys.removeValue(forKey: uuid)

        notify(key: key, added: false)
    }

    /// Posts notifications related to starting or stopping tracking progress for
    /// the specified ProgressKey.
    ///
    /// - Parameters:
    ///   - key: A ProgressKey instancce.
    ///   - added: Whether progress is being tracked or not.
    ///
    private func notify(key: ProgressKey, added: Bool) {
        let name: Notification.Name = added ? .startedTrackingProgress : .stoppedTrackingProgress
        NotificationCenter.default.post(name: name, object: key)
    }

    /// Get a ProgressKey for the specified UUID.
    ///
    /// - Parameter uuid: The UUID.
    /// - Returns: A ProgressKey instance.
    ///
    func keyForUUID(uuid: UUID) -> ProgressKey {
        // Just return an existing key.
        if let key = progressKeys[uuid] {
            return key
        }

        // Create a key and return it.
        let key = ProgressKey(uuid: uuid)
        progressKeys[uuid] = key
        return key
    }

}

extension Notification.Name {
    static let startedTrackingProgress = Notification.Name("startedTrackingProgress")
    static let stoppedTrackingProgress = Notification.Name("stoppedTrackingProgress")
}
