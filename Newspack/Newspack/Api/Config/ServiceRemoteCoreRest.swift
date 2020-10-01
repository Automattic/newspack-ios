import Foundation
import WordPressKit

enum ApiError: Error {
    case unexpectedDataFormat
}

/// Base class for core rest api service remotes.
///
class ServiceRemoteCoreRest {

    let api:WordPressCoreRestApi

    init(wordPressComRestApi api: WordPressCoreRestApi) {
        self.api = api
    }

}
