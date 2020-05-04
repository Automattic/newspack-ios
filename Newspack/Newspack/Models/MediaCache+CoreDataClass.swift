import Foundation
import UIKit
import CoreData

@objc(MediaCache)
public class MediaCache: NSManagedObject {

    func image() -> UIImage? {
        guard let data = self.data else {
            return nil
        }
        return UIImage(data: data)
    }

}
