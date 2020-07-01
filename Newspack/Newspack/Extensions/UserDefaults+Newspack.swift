import Foundation

extension UserDefaults {

    static let testDefaults = UserDefaults(suiteName: "NewspackTests")!

    static var shared: UserDefaults {
        return Environment.isTesting() ? testDefaults : standard
    }

}
