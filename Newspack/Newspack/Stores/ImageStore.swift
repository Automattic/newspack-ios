import Foundation
import CoreData
import WordPressFlux
import NewspackFramework

class ImageStore: Store {

    func createOrUpdateCachedMedia(context: NSManagedObjectContext, sourceURL: String, data: Data) -> MediaCache {
        let cached = getCachedMedia(context: context, sourceURL: sourceURL) ?? MediaCache(context: context)
        cached.sourceURL = sourceURL
        cached.dateCached = Date()
        cached.data = data
        return cached
    }

    func getCachedMedia(context: NSManagedObjectContext, sourceURL: String) -> MediaCache? {
        let request = MediaCache.defaultFetchRequest()
        request.predicate = NSPredicate(format: "sourceURL = %@", sourceURL)

        do {
            guard let cached = try context.fetch(request).first else {
                return nil
            }
            return cached
        } catch {
            // TODO: Handle error
            let error = error as NSError
            LogError(message: "getCachedMedia: " + error.localizedDescription)
            return nil
        }
    }

}
