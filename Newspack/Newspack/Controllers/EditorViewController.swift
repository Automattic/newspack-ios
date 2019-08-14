import Foundation
import Gutenberg
import Aztec

class EditorViewController: UIViewController {

    let saveTimerInterval: TimeInterval = 60
    var saveTimer: Timer?
    let coordinator: EditCoordinator

    private lazy var gutenberg: Gutenberg = {
        return Gutenberg(dataSource: coordinator, extraModules: [])
    }()

    init(coordinator: EditCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        stopSaveTimer()
        gutenberg.invalidate()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
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
