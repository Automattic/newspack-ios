import Foundation
import CoreData
import WordPressFlux

class StagedMediaUploader: NSObject {

    let resultsController: NSFetchedResultsController<StagedMedia>
    var currentUploadID: UUID?
    let dispatcher: ActionDispatcher
    var receipt: Receipt?

    init(site: Site, dispatcher: ActionDispatcher) {
        // Setup the FetchedResultsController
        let request = StagedMedia.defaultFetchRequest()
        request.predicate = NSPredicate(format: "originalFileName != NULL AND localFilePath != NULL AND site == %@", site)
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]

        let context = CoreDataManager.shared.mainContext
        resultsController = NSFetchedResultsController(fetchRequest: request,
                                                       managedObjectContext:context,
                                                       sectionNameKeyPath: nil,
                                                       cacheName: nil)
        // Configure the dispatcher
        self.dispatcher = dispatcher

        super.init()

        // Save the receipt
        self.receipt = dispatcher.subscribe { [weak self] (action) in
            self?.onDispatch(action: action)
        }

        resultsController.delegate = self
        try? resultsController.performFetch()
        uploadNext()
    }

    func onDispatch(action: Action) {
        guard let action = action as? MediaCreatedApiAction else {
            return
        }
        // NOTE: Its expected that this action will be dispatched before core data
        // is update to delete the stagedmedia record that was just uploaded.
        if let uuid = currentUploadID, uuid == action.uuid {
            currentUploadID = nil
        }
    }

    func uploadNext() {
        guard currentUploadID == nil else {
            // Busy
            LogDebug(message: "uploadNext: Busy")
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
        LogDebug(message: "uploadNext: \(nextMedia)")
        currentUploadID = nextMedia.uuid

        let service = ApiService.mediaService()
        service.createMedia(stagedUUID: nextMedia.uuid,
                            localFilePath: localFilePath,
                            filename: filename,
                            mimeType: mimeType,
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

