import UIKit
import AVKit
import CoreData
import NewspackFramework

/// Displays details about a photo asset
///
class MediaDetailViewController: UITableViewController {

    var asset: StoryAsset!

    lazy var mediaDataSource: MediaDetailDataSource = {
        return MediaDetailDataSource(asset: asset, presenter: self)
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
        if mediaDataSource.needsRefresh {
            mediaDataSource.reload()
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

extension MediaDetailViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return mediaDataSource.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaDataSource.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = mediaDataSource.row(indexPath: indexPath) else {
            return
        }
        row.callback()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = mediaDataSource.row(indexPath: indexPath) else {
            fatalError()
        }

        if row is MediaImageRow {
            return configureImageCell(tableView: tableView, indexPath: indexPath, row: row as! MediaImageRow)
        }

        return configureInfoCell(tableView: tableView, indexPath: indexPath, row: row as! MediaInfoRow)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sec = mediaDataSource.sections[section]
        return sec.title
    }

    func configureImageCell(tableView: UITableView, indexPath: IndexPath, row: MediaImageRow) -> ImageTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ImageTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.configureCell(image: row.image)
        return cell
    }

    func configureInfoCell(tableView: UITableView, indexPath: IndexPath, row: MediaInfoRow) -> UITableViewCell {
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

protocol MediaDetailsRow {
    var callback: () -> Void { get }
}

struct MediaInfoRow: MediaDetailsRow {
    let title: String
    let placeholder: String
    let callback: () -> Void
}

struct MediaImageRow: MediaDetailsRow {
    let image: UIImage?
    let callback: () -> Void
}

struct MediaDetailSection {
    let title: String?
    let rows: [MediaDetailsRow]
}

class MediaDetailDataSource {

    private let asset: StoryAsset
    private weak var presenter: UIViewController?
    private(set) var sections = [MediaDetailSection]()
    private(set) var needsRefresh = false

    init(asset: StoryAsset, presenter: UIViewController) {
        self.asset = asset
        self.presenter = presenter

        updateSections()
    }

    func reload() {
        updateSections()
    }

    func section(indexPath: IndexPath) -> MediaDetailSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> MediaDetailsRow? {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func updateSections() {
        var firstSection = MediaDetailSection(title: "", rows: [])

        if asset.assetType == .image {
            firstSection = buildPhotoSection()
        } else if asset.assetType == .video {
            firstSection = buildVideoSection()
        }

        sections = [
            firstSection,
            buildCaptionSection(),
            buildAltSection()
        ]
    }

    private func buildPhotoSection() -> MediaDetailSection {
        let image = buildRowImage()
        let row = MediaImageRow(image: image) { [weak self] in
            self?.showImage()
        }
        return MediaDetailSection(title: nil, rows: [row])
    }

    private func buildVideoSection() -> MediaDetailSection {
        let image = buildVideoImage()
        let row = MediaImageRow(image: image) { [weak self] in
            self?.showVideo()
        }
        return MediaDetailSection(title: nil, rows: [row])
    }

    private func buildRowImage() -> UIImage? {
        let height = CGFloat(ImageTableViewCell.imageHeight)
        let width = presenter?.view.readableContentGuide.layoutFrame.width ?? height * 2

        let size = CGSize(width: width, height: height)

        if let image = ImageResizer.shared.resizedImage(identifier: asset.uuid.uuidString, size: size) {
            return image
        }
        let folderManager = SessionManager.shared.folderManager
        guard
            let bookmark = asset.bookmark,
            let url = folderManager.urlFromBookmark(bookmark: bookmark),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }

        return ImageResizer.shared.resizeImage(image: image, identifier: asset.uuid.uuidString, fillingSize: size)
    }

    private func buildVideoImage() -> UIImage? {
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
    }

    private func buildCaptionSection() -> MediaDetailSection {
        var rows = [MediaInfoRow]()

        rows.append(MediaInfoRow(title: asset.caption, placeholder: Constants.captionPlaceholder, callback: { [weak self] in
            self?.showEditCaption()
        }))

        return MediaDetailSection(title: Constants.captionTitle, rows: rows)
    }

    private func buildAltSection() -> MediaDetailSection {
        var rows = [MediaInfoRow]()

        let title = asset.altText ?? ""
        rows.append(MediaInfoRow(title: title, placeholder: Constants.altPlaceholder, callback: { [weak self] in
            self?.showEditAltText()
        }))

        return MediaDetailSection(title: Constants.altTitle, rows: rows)
    }

    struct Constants {
        static let captionTitle = NSLocalizedString("Caption", comment: "Noun. An media caption.")
        static let captionPlaceholder = NSLocalizedString("Enter a caption", comment: "Instruction. A prompt to enter a caption for a media item.")
        static let altTitle = NSLocalizedString("Alt Text", comment: "Noun. The name of the Alternative Text attribute of an HTML tag.")
        static let altPlaceholder = NSLocalizedString("Enter alt text", comment: "Instruction. A prompt to enter alt text for a media item.")
    }
}

extension MediaDetailDataSource {

    private func showImage() {
        let folderManager = SessionManager.shared.folderManager
        guard
            let bookmark = asset.bookmark,
            let url = folderManager.urlFromBookmark(bookmark: bookmark),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return
        }

        let controller = MainStoryboard.instantiateViewController(withIdentifier: .imageView) as! ImageViewController
        controller.image = image
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        presenter?.present(controller, animated: true)
    }

    private func showVideo() {
        let folderManager = SessionManager.shared.folderManager
        guard
            let bookmark = asset.bookmark,
            let url = folderManager.urlFromBookmark(bookmark: bookmark)
        else {
            return
        }

        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        presenter?.present(controller, animated: true) {
            player.play()
        }
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
