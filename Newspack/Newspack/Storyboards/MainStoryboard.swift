import Foundation
import UIKit

class MainStoryboard {
    static func instantiateViewController(withIdentifier identifier: String) -> UIViewController {
        return UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}
