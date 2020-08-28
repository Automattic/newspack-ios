import Foundation

extension UserDefaults {

    private static let testDefaults = UserDefaults(suiteName: "NewspackTests")!
    private static let groupDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)!

    public static var shared: UserDefaults {
        return Environment.isTesting() ? testDefaults : groupDefaults
    }

}
