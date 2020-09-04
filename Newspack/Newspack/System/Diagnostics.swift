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

        LogInfo(message: "Counting entities in core data.")

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
            LogInfo(message: "Nothing saved in core data.")
            return
        }

        for (k, v) in counts {
            LogInfo(message: "\(k): has \(v) records.")
        }
    }


    static func countShadows() {
        LogInfo(message: "Counting shadows.")
        let manager = ShadowManager.init()
        let sites = manager.retrieveShadowSites()
        if sites.count == 0 {
            LogInfo(message: "No shadows found.")
            return
        }
        LogInfo(message: "Found \(sites.count) shadow site(s).")

        for site in sites {
            LogInfo(message: "Found \(site.stories.count) stories for \(site.title)")
        }

        let assets = manager.retrieveShadowAssets()
        LogInfo(message: "Found \(assets.count) shadow asset(s).")
    }

}
