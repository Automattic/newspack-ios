import UIKit
import CoreData

/// Displays details about a photo asset
///
class PhotoDetailViewController: UITableViewController {

    var asset: StoryAsset!

    lazy var photoDataSource: PhotoDetailDataSource = {
        return PhotoDetailDataSource(asset: asset, presenter: self)
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
        if photoDataSource.needsRefresh {
            photoDataSource.reload()
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

extension PhotoDetailViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return photoDataSource.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoDataSource.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = photoDataSource.row(indexPath: indexPath) else {
            return
        }
        row.callback()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = photoDataSource.row(indexPath: indexPath) else {
            fatalError()
        }

        if row is ImageRow {
            return configureImageCell(tableView: tableView, indexPath: indexPath, row: row as! ImageRow)
        }

        return configureInfoCell(tableView: tableView, indexPath: indexPath, row: row as! InfoRow)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sec = photoDataSource.sections[section]
        return sec.title
    }

    func configureImageCell(tableView: UITableView, indexPath: IndexPath, row: ImageRow) -> ImageTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ImageTableViewCell.self, for: indexPath)
        cell.configureCell(image: row.image)
        return cell
    }

    func configureInfoCell(tableView: UITableView, indexPath: IndexPath, row: InfoRow) -> UITableViewCell {
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

protocol PhotoDetailsRow {
    var callback: () -> Void { get }
}

struct InfoRow: PhotoDetailsRow {
    let title: String
    let placeholder: String
    let callback: () -> Void
}

struct ImageRow: PhotoDetailsRow {
    let image: UIImage?
    let callback: () -> Void
}

struct PhotoDetailSection {
    let title: String?
    let rows: [PhotoDetailsRow]
}

class PhotoDetailDataSource {

    private let asset: StoryAsset
    private weak var presenter: UIViewController?
    private(set) var sections = [PhotoDetailSection]()
    private(set) var needsRefresh = false

    init(asset: StoryAsset, presenter: UIViewController) {
        self.asset = asset
        self.presenter = presenter

        updateSections()
    }

    func reload() {
        updateSections()
    }

    func section(indexPath: IndexPath) -> PhotoDetailSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> PhotoDetailsRow? {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func updateSections() {
        sections = [
            buildPhotoSection(),
            buildCaptionSection(),
            buildAltSection()
        ]
    }

    private func buildPhotoSection() -> PhotoDetailSection {
        let image = buildRowImage()
        let row = ImageRow(image: image) { [weak self] in
            self?.showImage()
        }
        return PhotoDetailSection(title: nil, rows: [row])
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

    private func buildCaptionSection() -> PhotoDetailSection {
        var rows = [InfoRow]()

        rows.append(InfoRow(title: asset.caption, placeholder: Constants.captionPlaceholder, callback: { [weak self] in
            self?.showEditCaption()
        }))

        return PhotoDetailSection(title: Constants.captionTitle, rows: rows)
    }

    private func buildAltSection() -> PhotoDetailSection {
        var rows = [InfoRow]()

        let title = asset.altText ?? ""
        rows.append(InfoRow(title: title, placeholder: Constants.altPlaceholder, callback: { [weak self] in
            self?.showEditAltText()
        }))

        return PhotoDetailSection(title: Constants.altTitle, rows: rows)
    }

    struct Constants {
        static let captionTitle = NSLocalizedString("Caption", comment: "Noun. An image caption.")
        static let captionPlaceholder = NSLocalizedString("Enter a caption", comment: "Instruction. A prompt to enter a caption for an image.")
        static let altTitle = NSLocalizedString("Alt Text", comment: "Noun. The name of the Alternative Text attribute of an HTML image tag.")
        static let altPlaceholder = NSLocalizedString("Enter alt text", comment: "Instruction. A prompt to enter alt text for an image.")
    }
}

extension PhotoDetailDataSource {

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
