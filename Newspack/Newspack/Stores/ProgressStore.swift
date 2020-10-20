import Foundation
import UIKit

class ProgressStore {

    static let startedTrackingProgress = NSNotification.Name("startedTrackingProgress")
    static let stoppedTrackingProgress = NSNotification.Name("stoppedTrackingProgress")

    private var store = [UUID: Progress]()
    private var progressKeys = [UUID: ProgressKey]()

    func progress(for uuid: UUID) -> Progress? {
        return store[uuid]
    }

    func add(progress: Progress, for uuid: UUID) {
        remove(for: uuid) // remove stale progress if it exists.
        store[uuid] = progress
        _ = keyForUUID(uuid: uuid)
        notify(uuid: uuid, added: true)
    }

    func remove(for uuid: UUID) {
        guard let _ = store.removeValue(forKey: uuid) else {
            return
        }
        progressKeys.removeValue(forKey: uuid)

        notify(uuid: uuid, added: false)
    }

    private func notify(uuid: UUID, added: Bool) {
        let name = added ? ProgressStore.startedTrackingProgress : ProgressStore.stoppedTrackingProgress
        let obj = keyForUUID(uuid: uuid)
        NotificationCenter.default.post(name: name , object: obj)
    }

    func keyForUUID(uuid: UUID) -> ProgressKey {
        if let obj = progressKeys[uuid] {
            return obj
        }

        let obj = ProgressKey(uuid: uuid)
        progressKeys[uuid] = obj
        return obj
    }

}

class ProgressKey {
    let uuid: UUID
    init(uuid: UUID) {
        self.uuid = uuid
    }
}
