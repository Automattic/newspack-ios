import Foundation

public class Environment {

    public static func isTesting() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init() {}
}
