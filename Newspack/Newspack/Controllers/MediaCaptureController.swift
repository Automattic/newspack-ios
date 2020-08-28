import Foundation
import CoreServices
import UIKit
import WPMediaPicker
import NewspackFramework

/// A convenience class encapsulating the config and boiler-plate for the
/// WPMediaCapturePresenter
///
class MediaCaptureController: WPMediaCapturePresenter {

    /// Preferred initializer.
    ///
    /// - Parameters:
    ///   - viewController: The view controller that should present the internal
    ///   UIImagePickerController instance.
    ///   - onComplete: A completion call back. Useful to release the instance after
    /// work is done.
    ///
    init(presenting viewController: UIViewController, onComplete: @escaping (() -> Void)) {
        super.init(presenting: viewController)

        mediaType = [.image, .video]
        completionBlock = { mediaInfo in
            defer {
                onComplete()
            }
            guard let media = mediaInfo else {
                LogError(message: "WPMediaCapturePresenter completion block's mediaInfo was nil.")
                return
            }
            self.processCapturedMedia(mediaInfo: media)
        }
    }

    func processCapturedMedia(mediaInfo: [AnyHashable: Any]) {
        guard let mediaType = mediaInfo[UIImagePickerController.InfoKey.mediaType] as? String else {
            // This should not happen but log it just in case.
            LogError(message: "Media type undefined.")
            return
        }

        if mediaType == kUTTypeImage as String {
            processCapturedImage(mediaInfo: mediaInfo)

        } else if mediaType == kUTTypeMovie as String {
            processCapturedVideo(mediaInfo: mediaInfo)
        }
    }

    func processCapturedImage(mediaInfo: [AnyHashable: Any]) {
        guard
            let image = mediaInfo[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let metadata = mediaInfo[UIImagePickerController.InfoKey.mediaMetadata] as? [AnyHashable: Any] else
        {
            // This should not happen but log it just in case.
            LogError(message: "Image and metadata not found.")
            return
        }

        WPPHAssetDataSource.sharedInstance().add(image, metadata: metadata) { (asset, error) in
            guard let asset = asset as? PHAsset else {
                // The cast should work unless there was some other underlying error.
                if let error = error {
                    LogError(message: error.localizedDescription)
                }
                // Halt execution in dev builds to facilitate debugging of the error.
                assertionFailure()
                return
            }

            let action = AssetAction.importMedia(assets: [asset])
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }
    }

    func processCapturedVideo(mediaInfo: [AnyHashable: Any]) {
        guard let url = mediaInfo[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            LogError(message: "Media URL not found.")
            return
        }
        WPPHAssetDataSource.sharedInstance().addVideo(from: url) { (asset, error) in
            guard let asset = asset as? PHAsset else {
                // The cast should work unless there was some other underlying error.
                if let error = error {
                    LogError(message: error.localizedDescription)
                }
                // Halt execution in dev builds to facilitate debugging of the error.
                assertionFailure()
                return
            }

            let action = AssetAction.importMedia(assets: [asset])
            SessionManager.shared.sessionDispatcher.dispatch(action)
        }
    }

}
