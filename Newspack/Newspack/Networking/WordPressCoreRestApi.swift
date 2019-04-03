import Foundation
import WordPressKit


/// WordPressCoreRestApi is a wp/v2 endpoint focused API client.
/// All calls will target the v2 endpoints so it does away with the need
/// to specifiy an api version when constructing an endpoint URL.
///
class WordPressCoreRestApi: WordPressComRestApi {

    // TODO: It would be nice to not have to unwrap this optional.
    let baseEndpoint = "https://public-api.wordpress.com/wp/v2/sites/"
    var site: String!

    convenience init(oAuthToken: String? = nil, userAgent: String? = nil, site: String) {
        self.init(oAuthToken: oAuthToken, userAgent: userAgent)
        self.site = site
    }

    @available(*, unavailable)
    override init(oAuthToken: String?, userAgent: String?, backgroundUploads: Bool, backgroundSessionIdentifier: String, sharedContainerIdentifier: String?, localeKey: String) {
        super.init(oAuthToken: oAuthToken,
                    userAgent: userAgent,
                    backgroundUploads: backgroundUploads,
                    backgroundSessionIdentifier: backgroundSessionIdentifier,
                    sharedContainerIdentifier: sharedContainerIdentifier,
                    localeKey: localeKey)
    }

    /// Overrides the base class to construct a wp/v2 endpoint that includes the site.
    ///
    ///
    /// - Returns: The base endpoint url
    ///
    override func buildBaseURL() -> URL? {
        let path = baseEndpoint + site
        return URL(string: path)
    }
}
