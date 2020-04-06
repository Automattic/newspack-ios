import Foundation
import CocoaLumberjack

class Log {
    private init() {}

    private static func fileName(filePath: String) -> String {
        guard let index = filePath.lastIndex(of: "/") else {
            return filePath
        }
        return String(filePath.suffix(from: index))
    }

    static func info(message: String, file: String, function: String) {
        let name = fileName(filePath: file)
        DDLogInfo("ℹ️ INFO: \(name) \(function): \(message)")
    }

    static func error(message: String, file: String, function: String) {
        let name = fileName(filePath: file)
        DDLogError("🛑 ERROR: \(name) \(function): \(message)")
    }

    static func debug(message: String, file: String, function: String) {
        let name = fileName(filePath: file)
        DDLogDebug("🛠️ DEBUG: \(name) \(function): \(message)")
    }

    static func warn(message: String, file: String, function: String) {
        let name = fileName(filePath: file)
        DDLogWarn("⚠️ WARNING: \(name) \(function): \(message)")
    }

    static func setup() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
        DDLog.add(DDTTYLogger.sharedInstance) // Uses the console

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
}

public func LogInfo(message: String, file: String = #file, function: String = #function) {
    Log.info(message: message, file: file, function: function)
}

public func LogWarn(message: String, file: String = #file, function: String = #function) {
    Log.warn(message: message, file: file, function: function)
}

public func LogDebug(message: String, file: String = #file, function: String = #function) {
    Log.debug(message: message, file: file, function: function)
}

public func LogError(message: String, file: String = #file, function: String = #function) {
    Log.error(message: message, file: file, function: function)
}
