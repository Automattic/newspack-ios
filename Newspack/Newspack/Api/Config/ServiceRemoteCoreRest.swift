import Foundation
import WordPressKit
import WordPressFlux

/// Base class for core rest api service remotes.
///
class ServiceRemoteCoreRest {

    let api:WordPressCoreRestApi
    let dispatcher: ActionDispatcher

    init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        self.api = api
        self.dispatcher = dispatcher
    }

    func dispatch(action: Action) {
        dispatcher.dispatch(action)
    }
}
