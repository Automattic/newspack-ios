import Foundation
import WordPressKit


/// WordPressCoreRestApi is a wp/v2 endpoint focused API client.
/// All calls will target the v2 endpoints so it does away with the need
/// to specifiy an api version when constructing an endpoint URL.
///
class WordPressCoreRestApi: WordPressComRestApi {

    static let baseEndpoint = "https://public-api.wordpress.com/wp/v2/sites/"

    convenience init(oAuthToken: String? = nil, userAgent: String? = nil, site: String) {
        var asite = WordPressCoreRestApi.baseEndpoint
        if let url = URL(string: site),
            let host = url.host {
            asite = asite + host + url.path
            if url.pathExtension.count > 0 {
                asite = "" + asite.dropLast(url.lastPathComponent.count)
            }
        }
        // TODO: Handle the case where the passed site does not resolve to a URL.

        self.init(oAuthToken: oAuthToken, userAgent: userAgent,
                  backgroundUploads: false,
                  backgroundSessionIdentifier: WordPressComRestApi.defaultBackgroundSessionIdentifier,
                  sharedContainerIdentifier: nil,
                  localeKey: WordPressComRestApi.LocaleKeyDefault,
                  baseUrlString: asite)
    }
}
