import Foundation
import CoreData

class StagedMediaUploader: NSObject {


    let resultsController: NSFetchedResultsController<StagedMedia>
    var currentUploadID: UUID?

    init(site: Site) {
        let request = StagedMedia.defaultFetchRequest()
        request.predicate = NSPredicate(format: "originalFileName != NULL AND localFilePath != NULL AND site == %@", site)

        let context = CoreDataManager.shared.mainContext
        resultsController = NSFetchedResultsController(fetchRequest: request,
                                                       managedObjectContext:context,
                                                       sectionNameKeyPath: nil,
                                                       cacheName: nil)
        super.init()
        resultsController.delegate = self
        try? resultsController.performFetch()
    }

    func uploadNext() {
        guard currentUploadID == nil else {
            // Busy
            return
        }

        guard
            let nextMedia = resultsController.fetchedObjects?.first,
            let localFilePath = nextMedia.localFilePath,
            let filename = nextMedia.originalFileName,
            let mimeType = nextMedia.mimeType
        else {
            // Nothing to do.
            return
        }

        currentUploadID = nextMedia.uuid

        let service = ApiService.mediaService()
        service.createMedia(stagedUUID: nextMedia.uuid,
                            localFilePath: localFilePath,
                            filename: filename,
                            mimeType: mimeType, // TODO: Check that this is the correct format
                            title: nextMedia.title,
                            altText: nextMedia.altText,
                            caption: nextMedia.caption)
    }
}

extension StagedMediaUploader: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        uploadNext()
    }
}

