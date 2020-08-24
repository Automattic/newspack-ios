import UIKit

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

    func configureTextCell(tableView: UITableView, indexPath: IndexPath, row: InfoRow) -> TextViewTableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: TextViewTableViewCell.self, for: indexPath)
        cell.textView.text = row.title

        return cell
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

    let asset: StoryAsset
    weak var presenter: UIViewController?
    var sections = [PhotoDetailSection]()

    init(asset: StoryAsset, presenter: UIViewController) {
        self.asset = asset
        self.presenter = presenter

        updateSections()
    }

    func section(indexPath: IndexPath) -> PhotoDetailSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> PhotoDetailsRow? {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func updateSections() {
        sections = [
            buildPhotoSection(),
            buildCaptionSection(),
            buildAltSection()
        ]
    }

    func buildPhotoSection() -> PhotoDetailSection {
        let image = buildRowImage()
        let row = ImageRow(image: image) { [weak self] in
            self?.showImage()
        }
        return PhotoDetailSection(title: nil, rows: [row])
    }

    func buildRowImage() -> UIImage? {
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

    func buildCaptionSection() -> PhotoDetailSection {
        var rows = [InfoRow]()

        let placeholder = NSLocalizedString("Enter a caption", comment: "Instruction. A prompt to enter a caption for an image.")
        rows.append(InfoRow(title: asset.caption, placeholder: placeholder, callback: {
            // TODO: Edit caption.
        }))

        let title = NSLocalizedString("Caption", comment: "Noun. An image caption.")
        return PhotoDetailSection(title: title, rows: rows)
    }

    func buildAltSection() -> PhotoDetailSection {
        var rows = [InfoRow]()

        let placeholder = NSLocalizedString("Enter alt text", comment: "Instruction. A prompt to enter alt text for an image.")
        rows.append(InfoRow(title: asset.caption, placeholder: placeholder, callback: {
            // TODO: Edit alt text.
        }))

        let title = NSLocalizedString("Alt Text", comment: "Noun. The name of the Alternative Text attribute of an HTML image tag.")
        return PhotoDetailSection(title: title, rows: rows)
    }

}

extension PhotoDetailDataSource {

    func showImage() {
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

}
