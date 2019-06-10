import Foundation
import WordPressFlux

public typealias Event = Action

/// A Store that includes Event information when broadcasting changes to
/// its Observers.
///
/// Observers who want to receive event information should regester a handler
/// by calling `onChangeEvent(_: (Event) -> Void))` and keeping the returned
/// receipt for as long as they want updates.
///
class EventfulStore: Store {
    private let eventDispatcher = Dispatcher<Event>()

    /// Notifies all registered observers of a change event.
    ///
    func emitChangeEvent(event: Event) {
        eventDispatcher.dispatch(event)
        emitChange()
    }

    /// Registers a new observer, that will receive a tuple with the old and new
    /// state.
    ///
    func onChangeEvent(_ handler: @escaping (Event) -> Void) -> Receipt {
        return eventDispatcher.subscribe(handler)
    }
}
