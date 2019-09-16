import Foundation
import CocoaLumberjack

class Log {
    private init() {}

    static func info(message: String) {
        DDLogInfo("ℹ️ INFO: " + message)
    }

    static func error(message: String) {
        DDLogError("🛑 ERROR: " + message)
    }

    static func debug(message: String) {
        DDLogDebug("🛠️ DEBUG: " + message)
    }

    static func warn(message: String) {
        DDLogWarn("⚠️ WARNING: " + message)
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

public func LogInfo(message: String) {
    Log.info(message: message)
}

public func LogWarn(message: String) {
    Log.warn(message: message)
}

public func LogDebug(message: String) {
    Log.debug(message: message)
}

public func LogError(message: String) {
    Log.error(message: message)
}
