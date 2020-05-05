import Foundation
import CoreData

// MARK: - DefaultFetchable

/// Adds a helper method to NSManagedObjects that composes a defaultFetchRequest
/// that does not need to be decorated with generics like the boilerplate version.
/// Hat tip @jleandroperez.
protocol DefaultFetchable { }

extension DefaultFetchable where Self: NSManagedObject {
    static func defaultFetchRequest() -> NSFetchRequest<Self> {
        return NSFetchRequest(entityName: classnameWithoutNamespaces)
    }
}

extension NSManagedObject: DefaultFetchable {}
