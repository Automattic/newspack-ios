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
        NotificationCenter.default.addObserver(self, selector: #selector(handleStartedTrackingProgress(notification:)), name: ProgressStore.startedTrackingProgress, object: uuid)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoppedTrackingProgress(notification:)), name: ProgressStore.stoppedTrackingProgress, object: uuid)
    }

    func stopListeningForProgress() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func handleStartedTrackingProgress(notification: Notification) {
        guard let uuid = notification.object as? UUID else {
            return
        }
        progressView.observedProgress = StoreContainer.shared.progressStore.progress(for: uuid)
    }

    @objc func handleStoppedTrackingProgress(notification: Notification) {
        progressView.observedProgress = nil
    }

    func observeProgress(uuid: UUID) {
        startListeningForProgress(uuid: uuid)
        progressView.progress = 0
        progressView.observedProgress = StoreContainer.shared.progressStore.progress(for: uuid)
    }
}
