import Foundation

protocol RequestQueueDelegate {
    func itemEnqueued(item: Any)
}

class RequestQueue<Item: Comparable> {

    var delegate: RequestQueueDelegate?

    var queue = [Item]()
    var activeQueue = [Item]()
    var maxItems = 3

    func contains(item: Item) -> Bool {
        return queue.contains(item)
    }

    func append(item: Item) {
        guard !contains(item: item) else {
            return
        }
        queue.append(item)
        makeNextItemActive()
    }

    func remove(item: Item) {
        guard let idx = queue.index(of: item) else {
            return
        }
        queue.remove(at: idx)
        removeActive(item: item)
    }

    func removeAll() {
        queue.removeAll()
        activeQueue.removeAll()
    }


    // MARK: - Private

    private func appendActive(item: Item) {
        guard  !activeQueue.contains(item) else {
            return
        }
        activeQueue.append(item)
        delegate?.itemEnqueued(item: item)
    }

    private func removeActive(item: Item) {
        guard let idx = activeQueue.index(of: item) else {
            return
        }
        activeQueue.remove(at: idx)
        makeNextItemActive()
    }

    private func makeNextItemActive() {
        if activeQueue.count >= maxItems {
            return
        }
        let remaining = queue.filter({ !activeQueue.contains($0) })
        if let item = remaining.first {
            appendActive(item: item)
        }
    }

}
