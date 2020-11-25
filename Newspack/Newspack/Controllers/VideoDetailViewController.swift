import UIKit
import CoreData
import AVKit
import NewspackFramework

/// Displays details about a video asset
///
class VideoDetailViewController: UITableViewController {

    var asset: StoryAsset!

    lazy var videoDataSource: VideoDetailDataSource = {
        return VideoDetailDataSource(asset: asset, presenter: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard asset != nil else {
            fatalError()
        }

        configureCells()
        configureNavbar()
        configureToolbar()
        configureStyle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // This is a little annoying but it's the simplest mechanism to refresh
        // cells after an edit.
        if videoDataSource.needsRefresh {
            videoDataSource.reload()
            tableView.reloadData()
        }
    }

    func configureCells() {
        tableView.register(SimpleTableViewCell.self, forCellReuseIdentifier: SimpleTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "ImageTableViewCell", bundle: nil), forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
    }

    func configureNavbar() {
        navigationItem.title = asset.name
    }

    func configureToolbar() {
        navigationController?.setToolbarHidden(true, animated: true)
    }

    func configureStyle() {
        Appearance.style(tableView: tableView)
    }

}

// MARK: - Table view related

extension VideoDetailViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return videoDataSource.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoDataSource.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = videoDataSource.row(indexPath: indexPath) else {
            return
        }
        row.callback()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = videoDataSource.row(indexPath: indexPath) else {
            fatalError()
        }

        if row is VideoRow {
            return configureImageCell(tableView: tableView, indexPath: indexPath, row: row as! VideoRow)
        }

        return configureInfoCell(tableView: tableView, indexPath: indexPath, row: row as! VideoInfoRow)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sec = videoDataSource.sections[section]
        return sec.title
    }

    func configureImageCell(tableView: UITableView, indexPath: IndexPath, row: VideoRow) -> ImageTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ImageTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.configureCell(image: row.image)
        return cell
    }

    func configureInfoCell(tableView: UITableView, indexPath: IndexPath, row: VideoInfoRow) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTableViewCell.reuseIdentifier, for: indexPath)
        cell.accessoryType = .disclosureIndicator

        if row.title.count > 0 {
            cell.textLabel?.text = row.title
            cell.textLabel?.numberOfLines = 0
            Appearance.style(cell: cell)
        } else {
            cell.textLabel?.text = row.placeholder
            Appearance.style(placeholderCell: cell)
        }

        return cell
    }

}

// MARK: - Data Model

protocol VideoDetailsRow {
    var callback: () -> Void { get }
}

struct VideoInfoRow: VideoDetailsRow {
    let title: String
    let placeholder: String
    let callback: () -> Void
}

struct VideoRow: VideoDetailsRow {
    let image: UIImage?
    let callback: () -> Void
}

struct VideoDetailSection {
    let title: String?
    let rows: [VideoDetailsRow]
}

class VideoDetailDataSource {

    private let asset: StoryAsset
    private weak var presenter: UIViewController?
    private(set) var sections = [VideoDetailSection]()
    private(set) var needsRefresh = false

    init(asset: StoryAsset, presenter: UIViewController) {
        self.asset = asset
        self.presenter = presenter

        updateSections()
    }

    func reload() {
        updateSections()
    }

    func section(indexPath: IndexPath) -> VideoDetailSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> VideoDetailsRow? {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func updateSections() {
        sections = [
            buildVideoSection(),
            buildCaptionSection(),
            buildAltSection()
        ]
    }

    private func buildVideoSection() -> VideoDetailSection {
        let image = buildRowImage()
        let row = VideoRow(image: image) { [weak self] in
            self?.showVideo()
        }
        return VideoDetailSection(title: nil, rows: [row])
    }

    private func buildRowImage() -> UIImage? {

        let height = CGFloat(ImageTableViewCell.imageHeight)
        let width = presenter?.view.readableContentGuide.layoutFrame.width ?? height * 2

        let size = CGSize(width: width, height: height)

        let folderManager = SessionManager.shared.folderManager
        guard
            let bookmark = asset.bookmark,
            let url = folderManager.urlFromBookmark(bookmark: bookmark)
        else {
            return nil
        }

        if let image = ImageResizer.shared.resizedImage(identifier: url.path, size: size) {
            return image
        }

        let asset = AVURLAsset(url: url, options: nil)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 0, timescale: 1)

        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }

        return ImageResizer.shared.resizeImage(image: UIImage(cgImage: cgImage),
                                               identifier: url.path,
                                               fillingSize: size)

//        let height = CGFloat(ImageTableViewCell.imageHeight)
//        let width = presenter?.view.readableContentGuide.layoutFrame.width ?? height * 2
//
//        let size = CGSize(width: width, height: height)
//
//        if let image = ImageResizer.shared.resizedImage(identifier: asset.uuid.uuidString, size: size) {
//            return image
//        }
//        let folderManager = SessionManager.shared.folderManager
//        guard
//            let bookmark = asset.bookmark,
//            let url = folderManager.urlFromBookmark(bookmark: bookmark),
//            let image = UIImage(contentsOfFile: url.path)
//        else {
//            return nil
//        }
//
//        return ImageResizer.shared.resizeImage(image: image, identifier: asset.uuid.uuidString, fillingSize: size)
    }

    private func buildCaptionSection() -> VideoDetailSection {
        var rows = [VideoInfoRow]()

        rows.append(VideoInfoRow(title: asset.caption, placeholder: Constants.captionPlaceholder, callback: { [weak self] in
            self?.showEditCaption()
        }))

        return VideoDetailSection(title: Constants.captionTitle, rows: rows)
    }

    private func buildAltSection() -> VideoDetailSection {
        var rows = [VideoInfoRow]()

        let title = asset.altText ?? ""
        rows.append(VideoInfoRow(title: title, placeholder: Constants.altPlaceholder, callback: { [weak self] in
            self?.showEditAltText()
        }))

        return VideoDetailSection(title: Constants.altTitle, rows: rows)
    }

    struct Constants {
        static let captionTitle = NSLocalizedString("Caption", comment: "Noun. An video caption.")
        static let captionPlaceholder = NSLocalizedString("Enter a caption", comment: "Instruction. A prompt to enter a caption for an video.")
        static let altTitle = NSLocalizedString("Alt Text", comment: "Noun. The name of the Alternative Text attribute of an HTML video tag.")
        static let altPlaceholder = NSLocalizedString("Enter alt text", comment: "Instruction. A prompt to enter alt text for a video.")
    }
}

extension VideoDetailDataSource {

    private func showVideo() {

        let folderManager = SessionManager.shared.folderManager
        guard
            let bookmark = asset.bookmark,
            let url = folderManager.urlFromBookmark(bookmark: bookmark)
        else {
            return
        }

        // Create an AVPlayer, passing it the local video url path
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        presenter?.present(controller, animated: true) {
            player.play()
        }

//        let folderManager = SessionManager.shared.folderManager
//        guard
//            let bookmark = asset.bookmark,
//            let url = folderManager.urlFromBookmark(bookmark: bookmark),
//            let image = UIImage(contentsOfFile: url.path)
//        else {
//            return
//        }
//
//        let controller = MainStoryboard.instantiateViewController(withIdentifier: .imageView) as! ImageViewController
//        controller.image = image
//        controller.modalPresentationStyle = .fullScreen
//        controller.modalTransitionStyle = .crossDissolve
//        presenter?.present(controller, animated: true)
    }

    private func showEditCaption() {
        let title = Constants.captionTitle
        let text = asset.caption
        let placeholder = Constants.captionTitle
        let instructions = Constants.captionPlaceholder

        let model = TextFieldModel(title: title,
                                   text: text,
                                   placeholder: placeholder,
                                   instructions: instructions) { [weak self] (newValue) in
                                    self?.handleEditCaption(newValue: newValue)
        }

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .textField) as! TextFieldViewController
        controller.model = model

        presenter?.navigationController?.pushViewController(controller, animated: true)
    }

    private func showEditAltText() {
        let title = Constants.altTitle
        let text = asset.altText
        let placeholder = Constants.altTitle
        let instructions = Constants.altPlaceholder

        let model = TextFieldModel(title: title,
                                   text: text,
                                   placeholder: placeholder,
                                   instructions: instructions) { [weak self] (newValue) in
                                    self?.handleEditAltText(newValue: newValue)
        }

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .textField) as! TextFieldViewController
        controller.model = model

        presenter?.navigationController?.pushViewController(controller, animated: true)
    }

    private func handleEditCaption(newValue: String?) {
        let action = AssetAction.updateCaption(assetID: asset.uuid, caption: newValue ?? "")
        SessionManager.shared.sessionDispatcher.dispatch(action)
        needsRefresh = true
    }

    private func handleEditAltText(newValue: String?) {
        let action = AssetAction.updateAltText(assetID: asset.uuid, altText: newValue ?? "")
        SessionManager.shared.sessionDispatcher.dispatch(action)
        needsRefresh = true
    }

}
