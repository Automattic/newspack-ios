import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject {

    @nonobjc public class func defaultFetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

}
