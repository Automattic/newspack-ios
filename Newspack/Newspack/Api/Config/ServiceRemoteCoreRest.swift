import Foundation
import WordPressKit
import WordPressFlux

/// Base class for core rest api service remotes.
///
class ServiceRemoteCoreRest {

    let api:WordPressCoreRestApi

    init(wordPressComRestApi api: WordPressCoreRestApi) {
        self.api = api
    }

    func dispach(action: Action) {
        ActionDispatcher.global.dispatch(action)
    }
}
