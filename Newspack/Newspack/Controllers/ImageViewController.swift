import UIKit
import WordPressUI

/// A controller that displays an image. The image can be pinched and zoomed,
/// or zoomed in/out by double tapping.
/// Tap once to dismiss.
///
class ImageViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!

    lazy var flingableViewHandler: FlingableViewHandler = {
        let handler = FlingableViewHandler(targetView: self.scrollView)
        handler.delegate = self
        return handler
    }()

    lazy var doubleTapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        recognizer.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(recognizer)
        return recognizer
    }()

    lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        recognizer.numberOfTapsRequired = 1
        recognizer.require(toFail: self.doubleTapRecognizer)
        scrollView.addGestureRecognizer(recognizer)
        return recognizer
    }()

    var image: UIImage? {
        didSet {
            if isViewLoaded {
                configureImage()
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureImage()
        configureGestures()
        configureFlingableViewHandler()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centerImage()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard let scrollView = self?.scrollView else {
                return
            }
            self?.scrollViewDidZoom(scrollView)
        }, completion: nil)
    }

    func configureGestures() {
        _ = doubleTapRecognizer
        _ = tapRecognizer
    }

    func configureImage() {
        guard let img = image else {
            return
        }
        imageView.image = img
        imageView.sizeToFit()
        scrollView.contentSize = img.size
        centerImage()
    }

    func configureFlingableViewHandler() {
        flingableViewHandler.isActive = scrollView.zoomScale == scrollView.minimumZoomScale
    }

    func centerImage() {
        guard let image = imageView.image else {
            return
        }
        let scaleWidth = scrollView.frame.width / image.size.width
        let scaleHeight = scrollView.frame.height / image.size.height
        let zoomScale = min(scaleWidth, scaleHeight)
        scrollView.minimumZoomScale = zoomScale
        scrollView.zoomScale = zoomScale
        scrollViewDidZoom(scrollView)
    }

}

// MARK: - Actions

extension ImageViewController {

    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        let point = recognizer.location(in: imageView)
        let size = scrollView.frame.size

        let w = size.width / scrollView.maximumZoomScale
        let h = size.height / scrollView.maximumZoomScale
        let x = point.x - (w / 2)
        let y = point.y - (h / 2)
        let rect = CGRect(x: x, y: y, width: w, height: h)
        scrollView.zoom(to: rect, animated: true)
    }

}

// MARK: - ScrollView delegate.

extension ImageViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let w = scrollView.bounds.size.width - scrollView.contentSize.width
        let h = scrollView.bounds.size.height - scrollView.contentSize.height
        let x = max(w / 2, 0)
        let y = max(h / 2, 0)

        scrollView.contentInset = UIEdgeInsets(top: y, left: x, bottom: 0, right: 0)
    }

}

// MARK: - Flingable View Handler Delegate
extension ImageViewController: FlingableViewHandlerDelegate {

    func flingableViewHandlerDidBeginRecognizingGesture(_ handler: FlingableViewHandler) {
        scrollView.isMultipleTouchEnabled = false
    }

    func flingableViewHandlerWasCancelled(_ handler: FlingableViewHandler) {
        scrollView.isMultipleTouchEnabled = true
    }

    func flingableViewHandlerDidEndRecognizingGesture(_ handler: FlingableViewHandler) {
        let time = DispatchTime.now() + 0.2
        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
