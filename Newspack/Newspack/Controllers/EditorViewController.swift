import Foundation
import Gutenberg
import Aztec

class EditorViewController: UIViewController {

    let saveTimerInterval: TimeInterval = 60
    var saveTimer: Timer?
    var coordinator: EditCoordinator?
    @IBOutlet var saveButton: UIBarButtonItem!

    private lazy var gutenberg: Gutenberg = {
        guard coordinator != nil else {
            fatalError("An EditCoordinator must be assigned before accessing the gutenberg property.")
        }
        return Gutenberg(dataSource: coordinator!, extraModules: [])
    }()

    deinit {
        stopSaveTimer()
        gutenberg.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureGutenberg()
        gutenberg.delegate = self
    }

    func configureGutenberg() {
        view.backgroundColor = .white
        gutenberg.rootView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gutenberg.rootView)

        view.leftAnchor.constraint(equalTo: gutenberg.rootView.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: gutenberg.rootView.rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: gutenberg.rootView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: gutenberg.rootView.bottomAnchor).isActive = true
    }

    @IBAction func handleSaveButtonTapped() {

    }

    func handleSaveTimer() {
        gutenberg.requestHTML()
    }

    func startSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveTimerInterval, repeats: true, block: { [weak self](timer) in
            self?.handleSaveTimer()
        })
    }

    func stopSaveTimer() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
}

extension EditorViewController: GutenbergBridgeDelegate {
    func gutenbergDidProvideHTML(title: String, html: String, changed: Bool) {
        guard changed else {
            return
        }
        // TODO:
    }

    func gutenbergDidRequestMedia(from source: MediaPickerSource, filter: [MediaFilter]?, with callback: @escaping MediaPickerDidPickMediaCallback) {

    }

    func gutenbergDidRequestImport(from url: URL, with callback: @escaping MediaPickerDidPickMediaCallback) {

    }

    func gutenbergDidRequestMediaUploadSync() {

    }

    func gutenbergDidRequestMediaUploadActionDialog(for mediaID: Int32) {

    }

    func gutenbergDidRequestMediaUploadCancelation(for mediaID: Int32) {

    }

    func gutenbergDidMount(unsupportedBlockNames: [String]) {
        startSaveTimer()
    }

    func gutenbergDidEmitLog(message: String, logLevel: LogLevel) {

    }
}
