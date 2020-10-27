import UIKit

class ProgressCell: UITableViewCell {

    @IBOutlet var progressView: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        progressView.trackTintColor = .clear
        progressView.trackImage = nil
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {
            stopListeningForProgress()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        stopListeningForProgress()
    }

    func startListeningForProgress(uuid: UUID) {
        let key = StoreContainer.shared.progressStore.keyForUUID(uuid: uuid)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStartedTrackingProgress(notification:)), name: .startedTrackingProgress, object: key)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoppedTrackingProgress(notification:)), name: .stoppedTrackingProgress, object: key)
    }

    func stopListeningForProgress() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func handleStartedTrackingProgress(notification: Notification) {
        guard let key = notification.object as? ProgressKey else {
            return
        }
        progressView.observedProgress = StoreContainer.shared.progressStore.progress(for: key.uuid)
    }

    @objc func handleStoppedTrackingProgress(notification: Notification) {
        progressView.observedProgress = nil
    }

    func observeProgress(uuid: UUID) {
        startListeningForProgress(uuid: uuid)
        progressView.progress = 0
        let key = StoreContainer.shared.progressStore.keyForUUID(uuid: uuid)
        progressView.observedProgress = StoreContainer.shared.progressStore.progress(for: key.uuid)
    }
}
