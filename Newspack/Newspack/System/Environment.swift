import Foundation

class Environment {

    static func isTesting() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init() {}
}
