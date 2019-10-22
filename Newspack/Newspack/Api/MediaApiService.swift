import Foundation
import WordPressFlux

class MediaApiService: ApiService {

    let remote: MediaServiceRemote

    deinit {
        LogDebug(message: "MediaApiService deinit")
    }

    override init(wordPressComRestApi api: WordPressCoreRestApi, dispatcher: ActionDispatcher) {
        remote = MediaServiceRemote(wordPressComRestApi: api)
        super.init(wordPressComRestApi: api, dispatcher: dispatcher)
    }

    func fetchMediaItems(filter:[String: AnyObject], page: Int, perPage: Int = 100) {
        remote.fetchMediaItems(filter: filter, page: page, perPage: perPage) { (items, error) in

            guard let items = items else {
                // TODO: Need to update WordPressComRestApi to detect code = `rest_post_invalid_page_number` for an http 400 error.
                // For now, assume the error is due to inalid page and go ahead and set hasMore to false.
                self.dispatch(action: MediaItemsFetchedApiAction(payload: nil,
                                                                 error: error,
                                                                 count: 0,
                                                                 filter: filter,
                                                                 page: page,
                                                                 hasMore: false))
                return
            }

            self.dispatch(action: MediaItemsFetchedApiAction(payload: items,
                                                             error: nil,
                                                             count: items.count,
                                                             filter: filter,
                                                             page: page,
                                                             hasMore: items.count == perPage))
        }
    }

    func fetchMedia(mediaID: Int64) {
        remote.fetchMedia(mediaID: mediaID) { (media, error) in
            self.dispatch(action: MediaFetchedApiAction(payload: media, error: error, mediaID: mediaID))
        }
    }

}
