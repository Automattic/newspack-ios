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
        tableView.register(UINib(nibName: "TextViewTableViewCell", bundle: nil), forCellReuseIdentifier: TextViewTableViewCell.reuseIdentifier)
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = photoDataSource.row(indexPath: indexPath) else {
            fatalError()
        }

        switch row {
        case is InfoRow:
            return configureTextCell(tableView: tableView, indexPath: indexPath, row: row as! InfoRow)
        case is ImageRow:
            return configureImageCell(tableView: tableView, indexPath: indexPath, row: row as! ImageRow)
        default:
            break
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleTableViewCell.reuseIdentifier, for: indexPath)
        Appearance.style(cell: cell)
        return cell
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

}

// MARK: - Data Model

protocol PhotoDetailsRow {}

struct InfoRow: PhotoDetailsRow {
    let title: String
    let callback: () -> Void
}

struct ImageRow: PhotoDetailsRow {
    let image: UIImage?
    let callback: () -> Void
}

struct PhotoDetailSection {
    let rows: [PhotoDetailsRow]
}

class PhotoDetailDataSource {

    let asset: StoryAsset
    weak var presenter: UIViewController?
    var sections = [PhotoDetailSection]()

    init(asset: StoryAsset, presenter: UIViewController) {
        self.asset = asset

        updateSections()
    }

    func updateSections() {
        sections = [
            buildPhotoSection(),
            buildInfoSection()
        ]
    }

    func buildPhotoSection() -> PhotoDetailSection {
        let image = buildRowImage()
        let row = ImageRow(image: image) { [weak self] in
            self?.showImage()
        }
        return PhotoDetailSection(rows: [row])
    }

    func buildRowImage() -> UIImage? {
        let size = CGSize(width: 300, height: 100)

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

    func buildInfoSection() -> PhotoDetailSection {
        var rows = [InfoRow]()

        rows.append(InfoRow(title: asset.caption, callback: {

        }))

        return PhotoDetailSection(rows: rows)
    }

    func section(indexPath: IndexPath) -> PhotoDetailSection? {
        return sections[indexPath.section]
    }

    func row(indexPath: IndexPath) -> PhotoDetailsRow? {
        return sections[indexPath.section].rows[indexPath.row]
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
