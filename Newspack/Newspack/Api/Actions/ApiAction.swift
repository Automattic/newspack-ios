import Foundation
import WordPressFlux

/// Api Action protocol.  All actions dispatched from the API layer should
/// implement this protocol.
///
protocol ApiAction: Action {
    var error: Error? { get }

    func isError() -> Bool
}

extension ApiAction {
    func isError() -> Bool {
        return error != nil
    }
}
