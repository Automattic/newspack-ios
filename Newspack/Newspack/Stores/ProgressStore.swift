import Foundation
import UIKit

class ProgressStore {

    static let startedTrackingProgress = NSNotification.Name("startedTrackingProgress")
    static let stoppedTrackingProgress = NSNotification.Name("stoppedTrackingProgress")

    private var store = [UUID: Progress]()

    func progress(for uuid: UUID) -> Progress? {
        return store[uuid]
    }

    func add(progress: Progress, for uuid: UUID) {
        remove(for: uuid) // remove stale progress if it exists.
        store[uuid] = progress
        notify(uuid: uuid, added: true)
    }

    func remove(for uuid: UUID) {
        guard let _ = store.removeValue(forKey: uuid) else {
            return
        }
        notify(uuid: uuid, added: false)
    }

    func notify(uuid: UUID, added: Bool) {
        let name = added ? ProgressStore.startedTrackingProgress : ProgressStore.stoppedTrackingProgress
        NotificationCenter.default.post(name: name , object: uuid)
    }

}
