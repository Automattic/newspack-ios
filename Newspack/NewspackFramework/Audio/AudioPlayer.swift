import Foundation
import AVFoundation

/// Protocol for the AudioPlayer's delegate.
///
public protocol AudioPlayerDelegate: class {

    /// Called when the current playback time changes.  Useful for updating UI indicating the current play time.
    ///
    /// - Parameters:
    ///   - player: The AudioPlayer instance.
    ///   - currentTime: The playback time of the current audio track.
    ///
    func audioPlayer(_ player: AudioPlayer, currentTime: TimeInterval)

    /// Called when the player has finished loading a new track and it's duration is known.
    ///
    /// - Parameters:
    ///   - player: The AudioPlayer instance.
    ///   - duration: The duration of the current audio track.
    ///
    func audioPlayer(_ player: AudioPlayer, loadedTrackWithDuration duration: TimeInterval)

    /// Called when the player's playback rate has changed.
    ///
    /// - Parameters:
    ///   - player: The AudioPlayer instance.
    ///   - playing: True if the player is still playing (rate > 0). False otherwise.
    ///
    func audioPlayer(_ player: AudioPlayer, changedPlayback playing: Bool)

    /// Called when the player's ready state changes. Useful for enabling or disabling UI assets.
    ///
    /// - Parameters:
    ///   - player: The AudioPlayer instance.
    ///   - isReady: True if the player is ready. False otherwise.
    ///
    func audioPlayer(_ player: AudioPlayer, isReady: Bool)

    /// Called when the player has finished playing a track.
    ///
    /// - Parameter player: The AudioPlayer instance.
    ///
    func audioPlayerFinishedPlaying(_ player: AudioPlayer)
}


/// A basic audio player.
///
public class AudioPlayer: NSObject {

    public weak var delegate: AudioPlayerDelegate?

    /// References to observers and KVO tokens that need handling during deinit.
    private var timeObserver: Any?
    private var rateToken: NSKeyValueObservation?
    private var statusToken: NSKeyValueObservation?

    // Internal AVPlayer reference.
    private var player: AVPlayer?

    /// Returns true when the player is ready to play a track. False otherwise.
    ///
    public var ready: Bool {
        player?.status == .readyToPlay
    }

    /// Returns the current playback rate. A rate of 0.0 indicates the player is stopped or paused.
    /// A rate of 1.0 indicates normal playback speed. Other values indicate slower or faster
    /// playback, e.g. 0.5 is half speed, 2.0 is double speed.
    /// Playback rates are constrained between 0.0 and 2.0.
    /// Possible playback rates depend on the audio asset that is being played. Not all rates will be supported.
    ///
    public var rate: Float {
        get {
            player?.rate ?? 1.0
        }
        set {
            guard newValue >= 0 && newValue <= 2 else {
                return
            }
            player?.rate = newValue
        }
    }

    /// The current playback time of the current audio track.
    ///
    public var currentTime: TimeInterval {
        player?.currentTime().seconds ?? 0
    }

    /// The duration of the current audio track.
    ///
    public var duration: TimeInterval {
        player?.currentItem?.duration.seconds ?? 0
    }

    /// Returns true if the player is currently playing. False otherwise.
    ///
    public var isPlaying: Bool  {
        Float(player?.rate ?? 0.0) > 0.0
    }

    /// A convenience method. Call once to let the system know the app supports long-form audio.
    ///
    @discardableResult static public func configureSession() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
        } catch {
            print("Failed to set audio session route sharing policy: \(error)")
            return false
        }
        return true
    }

    // MARK: - Lifecycle

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        rateToken?.invalidate()
        statusToken?.invalidate()
    }

    public init(delegate: AudioPlayerDelegate?) {
        self.delegate = delegate
        super.init()
    }

    // MARK: Public methods

    /// Attempts to play an audio file at the specified file URl.
    ///
    /// - Parameter fileURL: URL pointing to a local audio file.
    ///
    public func play(fileURL: URL) {
        guard fileURL.isFileURL else {
            LogError(message: "The supplied url was not a file URL.")
            return
        }
        let asset = AVAsset(url: fileURL)
        play(asset: asset)
    }

    /// Attempts to play an audio AVAsset. The playable and duration keys will be
    /// loaded before playing so the associated properties are available.
    ///
    /// - Parameter asset: An audio AVAsset instance.
    public func play(asset: AVAsset) {
        let keys = ["playable", "duration"]
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            DispatchQueue.main.async {
                let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: keys)
                self?.playItem(playerItem: item)
            }
        }
    }

    /// Attempts to play the audio associated with an AVPlayerItem instance.
    ///
    /// - Parameter playerItem: An AVPlayerItem instance.
    ///
    public func playItem(playerItem: AVPlayerItem) {
        guard playerItem.asset.isPlayable else {
            LogError(message: "The supplied AVPlayerItem's aset was not playable.")
            return
        }
        defer {
            delegate?.audioPlayer(self, loadedTrackWithDuration: duration)
            player?.play()
        }
        guard let player = player else {
            createPlayer(with: playerItem)
            return
        }
        player.replaceCurrentItem(with: playerItem)
    }

    /// Play the current audio track.
    ///
    public func play() {
        player?.play()
    }

    /// Pause the current audio track.
    ///
    public func pause() {
        player?.pause()
    }

    /// Stop the current audio track setting the current playbcak time to 0.0.
    ///
    public func stop() {
        player?.pause()
        seek(to: 0)
    }

    /// Set the current playback time.
    ///
    /// - Parameter to: The desired playback time.
    ///
    public func seek(to: TimeInterval) {
        guard
            to <= duration,
            let timescale = player?.currentItem?.currentTime().timescale
        else {
            return
        }
        player?.seek(to: CMTime(seconds: to, preferredTimescale: timescale))
    }

    // MARK: - Non-public methods.

    /// Factory method to create an AVPlayer instance.
    ///
    /// - Parameter playerItem: An AVPlayerItem to use when instantiating the player.
    ///
    func createPlayer(with playerItem: AVPlayerItem) {
        player = AVPlayer(playerItem: playerItem)
        configurePlayer()
    }

    /// Configures various observers of the specified player's properties and states.
    ///
    /// - Parameter player: The AVPlayer instance.
    ///
    func configurePlayer() {
        guard let player = player else {
            return
        }

        // Invoke callback every half second
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [unowned self] time in
            self.handleCurrentTimeChanged(seconds: time.seconds)
        }

        rateToken = player.observe(\.rate, options: [.new]) { [unowned self] (_, _) in
            self.handleRateDidChange()
        }

        statusToken = player.observe(\.status, options: [.new]) { [unowned self] (_, _) in
            self.handlePlayerReadyStatusChanged()
        }
    }

    /// Called by the rate observer. Notifies delegates of changes,
    /// whether the player is playing or paused, and when a track is finished playing.
    ///
    func handleRateDidChange() {
        // Informs delegate of play, pause, and speed changes.
        delegate?.audioPlayer(self, changedPlayback: isPlaying)
        guard
            let time = player?.currentTime(),
            let duration = player?.currentItem?.duration,
            time.seconds == duration.seconds
        else {
            return
        }
        delegate?.audioPlayerFinishedPlaying(self)
    }

    /// Called by time observer. Notifies delegates of playback time changes.
    ///
    /// - Parameter seconds: The current playback time in seconds.
    ///
    func handleCurrentTimeChanged(seconds: TimeInterval) {
        self.delegate?.audioPlayer(self, currentTime: seconds)
    }

    /// Called by the ready state observer. Notifies delegates of ready status changes.
    ///
    func handlePlayerReadyStatusChanged() {
        self.delegate?.audioPlayer(self, isReady: self.ready)
    }
}
