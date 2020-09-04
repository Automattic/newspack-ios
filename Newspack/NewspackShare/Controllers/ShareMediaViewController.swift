import UIKit
import NewspackFramework

class ShareMediaViewController: UIViewController {

    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var stackView: UIStackView!

    let minThumbSize = CGFloat(88)
    let interItemSpacing = CGFloat(2)

    let shadowManager = ShadowManager()
    var shadowSites = [ShadowSite]()
    var targetStory: ShadowStory?
    var imageURLs = [URL]()

    lazy var extracter: ShareExtractor = {
        guard let tmpDir = FolderManager.createTemporaryDirectory() else {
            // This should never happen.
            fatalError()
        }
        return ShareExtractor(extensionContext: self.extensionContext!, tempDirectory: tmpDir)
    }()

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView?.reloadData()
        }, completion: nil)

        super.viewWillTransition(to: size, with: coordinator)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()
        configureNav()
        configureShadows()

        guard validateData() else {
            interruptSharing()
            return
        }
        // TODO: Check that we have valid data to work with.
        // There should be shadow sites, and at least one target story.
        // If missing show error.


        configureSharedItems()
    }

    func configureStyle() {
        ShareAppearance.style(view: view, tableView: tableView)
    }

    func configureNav() {
        navigationItem.title = NSLocalizedString("Share", comment: "Verb. Title of the screen shown when sharing from another app to Newspack.")
    }

    func configureShadows() {
        shadowSites = shadowManager.retrieveShadowSites()

        guard
            let currentSiteIdentifer = UserDefaults.shared.string(forKey: AppConstants.currentSiteIDKey),
            let currentStoryIdentifier = UserDefaults.shared.string(forKey: AppConstants.lastSelectedStoryFolderKey + currentSiteIdentifer)
        else {
            return
        }
        for site in shadowSites {
            for story in site.stories {
                if story.uuid == currentStoryIdentifier {
                    targetStory = story
                    return
                }
            }
        }
    }

    func configureSharedItems() {
        extracter.loadShare { (extracted) in
            self.handleSharedItems(items: extracted)
        }
    }

}

// MARK: - Validation and prompts

extension ShareMediaViewController {

    /// In order to share to the main app, the main app must have at least one
    /// site and at least one story. Since we don't have direct access to the main
    /// app's data, we'll trust that shadowSites are an accurate reflection. If
    /// either shadowSites are empty, or there is not a target story retrieved
    /// we'll assume the app has no sites or stories.
    /// Note that there is an edge case where shadowSites and a targetStory could
    /// be stale, and the app actually have no sites or stories (e.g. if the site
    /// or story folders were manually deleted via the files app.
    ///
    func validateData() -> Bool {
        guard
            shadowSites.count > 0,
            let _ = targetStory
        else {
            return false
        }

        return true
    }

    func interruptSharing() {
        stackView.isHidden = true

        let alertTitle = NSLocalizedString("Unable to share", comment: "The title of an error message shown when a user tries to share but the app is not in a state where sharing is possible..")
        let alertMessage = NSLocalizedString("Please launch the Newspack app, log in to your site, and make sure you have at least one story to share to, then try again.", comment: "A message shown in a prompt when trying to share to the app but there are not yet any sites or stories in the app.")
        let actionTitle = NSLocalizedString("OK", comment: "OK. A button title. Tapping closes the share screen.")
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)

        let action = UIAlertAction(title: actionTitle, style: .default, handler: { [weak self] _ in
            self?.cancelSharing()
        })
        alert.addAction(action)

        present(alert, animated: true, completion: nil)
    }

    func cancelSharing() {
        let error = NSError(domain: "com.auttomattic.newspack.share", code: 0, userInfo: nil)
        extensionContext?.cancelRequest(withError: error)
    }

}

// MARK: - Shared Item Wrangling

extension ShareMediaViewController {

    func handleSharedItems(items: ExtractedShare) {
        // Obtain image previews for each shared image.
        imageURLs = items.images.map { (item) -> URL in
            return item.url
        }

        collectionView.reloadData()
    }

    func processSharedItems() {
        let movedImages = moveImages(images: imageURLs)
        castShadows(images: movedImages)
    }

    func moveImages(images: [URL]) -> [URL] {
        let groupFolder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier)
        var movedImages = [URL]()
        for image in imageURLs {
            let destination = FileManager.default.availableFileURL(for: image.lastPathComponent, isDirectory: false, relativeTo: groupFolder)
            do {
                try FileManager.default.copyItem(at: image, to: destination)
                movedImages.append(destination)
            } catch {
                print(error)
            }
        }
        return movedImages
    }

    func castShadows(images: [URL]) {
        guard let story = targetStory else {
            // TODO: Handle error
            return
        }

        let folderManager = FolderManager()
        var shadows = [ShadowAsset]()
        for image in images {
            guard let data = folderManager.bookmarkForURL(url: image) else {
                continue
            }
            let asset = ShadowAsset(storyUUID: story.uuid, bookmarkData: data)
            shadows.append(asset)
        }

        shadowManager.storeShadowAssets(assets: shadows)
    }

    func thumbnailForImage(at url: URL, size: CGSize) -> UIImage? {
        if let thumb = ImageResizer.shared.resizedImage(identifier: url.path, size: size) {
            return thumb
        }

        guard
            url.isFileURL,
            let image = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }

        return ImageResizer.shared.resizeImage(image: image, identifier: url.path, fillingSize: size)
    }

}

// MARK: - Actions

extension ShareMediaViewController {

    @IBAction func handleSaveTapped(sender: UIBarButtonItem) {
        processSharedItems()
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    @IBAction func handleCancelTapped(sender: UIBarButtonItem) {
        cancelSharing()
    }

}

// MARK: - Table View Related

extension ShareMediaViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return shadowSites.count > 0 ? 1 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let _ = targetStory else {
            return 0
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TargetSiteCellIdentifier", for: indexPath)

        ShareAppearance.style(cell: cell)

        cell.textLabel?.text = targetStory?.title
        cell.detailTextLabel?.text = NSLocalizedString("Change", comment: "Verb. An action. Indicates that a selection can be changed via an interaction.")
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = UIStoryboard.init(name: "MainInterface", bundle: nil).instantiateViewController(withIdentifier: "StorySelectorViewController") as? StorySelectorViewController else {
            return
        }

        controller.delegate = self
        controller.shadowSites = shadowSites
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Share to", comment: "A title. What follows is the destination of where things will be shared.")
    }

}

// MARK: - Story Selector Delegate

extension ShareMediaViewController: StorySelectorViewControllerDelegate {

    func didSelectStory(story: ShadowStory) {
        targetStory = story
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }

}

// MARK: - Collection View Related

extension ShareMediaViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCellReuseIdentifier", for: indexPath) as! PhotoCell

        let url = imageURLs[indexPath.row]
        let thumbnail = thumbnailForImage(at: url, size: CGSize(width: minThumbSize, height: minThumbSize))
        cell.imageView.image = thumbnail

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var availableWidth = collectionView.bounds.width
        availableWidth += interItemSpacing // add one to the available width to allow for the last cell

        let count = floor(availableWidth / minThumbSize) // minThumbSize is inclusive of padding
        let side = (availableWidth / count) - interItemSpacing // Subtract spacing to get correct width.
        let size =  CGSize(width: side, height: side)

        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionHeaderView", for: indexPath) as? CollectionHeaderView {
            ShareAppearance.style(collectionHeader: sectionHeader)
            sectionHeader.textLabel.text = NSLocalizedString("Photos", comment: "Noun. A collection of thumbnails of images the user is sharing.").uppercased()
            return sectionHeader
        }
        return CollectionHeaderView()
    }

}
