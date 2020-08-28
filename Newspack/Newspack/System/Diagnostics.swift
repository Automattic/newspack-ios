import Foundation
import CoreData
import NewspackFramework

class Diagnostics {

    static func countEntitiesInCoreData() {

        // Get counts of everything currently saved to core data.
        let context = CoreDataManager.shared.mainContext
        guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
            return
        }

        LogDebug(message: "Diagnostics: Counting entities in core data.")

        let names:[String] = model.entities.compactMap { (entity) -> String in
            guard !entity.isAbstract, let name = entity.name else {
                return ""
            }
            return name
        }

        var counts = [String: Int]()
        for name in names {
            guard name != "" else {
                continue
            }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            if let count = try? context.count(for: fetchRequest) {
                if count == 0 {
                    continue
                }
                counts[name] = count
            }
        }

        if counts.count == 0 {
            LogDebug(message: "Diagnostics: Nothing saved in core data.")
            return
        }

        for (k, v) in counts {
            LogDebug(message: "\(k): has \(v) records.")
        }
    }


}
