import Foundation

protocol RequestQueueDelegate {
    associatedtype Item
    func itemEnqueued(item: Item)
}


/// A queue manager intended for keeping track of pending and active API requests
/// (hence the name) but generic enough for other uses.
/// The next available item is automatically moved into the internal array of
/// "active" items, and the delegate notified, when an item is removed.
/// Some properties and methods should be privated but are left as internal for
/// testing purposes.
///
class RequestQueue<Item: Comparable, Delegate: RequestQueueDelegate> where Delegate.Item == Item {

    var delegate: Delegate?

    var queue = [Item]()
    var activeQueue = [Item]()
    var maxItems = 3

    /// Whether the specified item is contained in the queue.
    ///
    /// - Parameter item: The item to inspect.
    /// - Returns: True if found.
    ///
    func contains(item: Item) -> Bool {
        return queue.contains(item)
    }

    /// Appends the specified item to the end of the queue. If appropriate the
    /// item is made "active".
    ///
    /// - Parameter item: The item to append.
    ///
    func append(item: Item) {
        guard !contains(item: item) else {
            return
        }
        queue.append(item)
        makeNextItemActive()
    }

    /// Removes the specified item from the queue. If appropriate the next item
    /// is made "active".
    ///
    /// - Parameter item: The item to remove.
    ///
    func remove(item: Item) {
        guard let idx = queue.index(of: item) else {
            return
        }
        queue.remove(at: idx)
        removeActive(item: item)
    }

    /// Removes all items from the queue.
    ///
    func removeAll() {
        queue.removeAll()
        activeQueue.removeAll()
    }

    // MARK: - Private

    /// Internal method for appending an item to the active queue. The
    /// delegate is notified.
    ///
    private func appendActive(item: Item) {
        guard  !activeQueue.contains(item) else {
            return
        }
        activeQueue.append(item)
        delegate?.itemEnqueued(item: item)
    }

    /// Internal method for removing an item from the active queue. The next
    /// available item is added to the active queue if appropriate.
    ///
    private func removeActive(item: Item) {
        guard let idx = activeQueue.index(of: item) else {
            return
        }
        activeQueue.remove(at: idx)
        makeNextItemActive()
    }

    /// Attempts to make the next item in the queue an active item, and add it
    /// into the active queue.
    ///
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
