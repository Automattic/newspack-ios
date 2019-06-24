import Foundation
import WordPressKit

/// WordPressCoreRestApi is a wp/v2 endpoint focused API client.
/// All calls will target the v2 endpoints so it does away with the need
/// to specifiy an api version when constructing an endpoint URL.
///
class WordPressCoreRestApi: WordPressComRestApi {

    static let baseEndpoint = "https://public-api.wordpress.com/wp/v2/sites/"

    /// Compose the base api endpoint for a specific site.
    ///
    /// - Parameter site: The site for the API
    /// - Returns: The endpoint for the site.
    ///
    static func baseEndpointForSite(_ site: String) -> String {
        let str = site.hasPrefix("http") ? site : "http://" + site

        guard let url = URL(string: str), let host = url.host else {
            print(str)
            return baseEndpoint
        }

        var endpoint = baseEndpoint
        endpoint.append(host)
        endpoint.append(url.path)

        if url.pathExtension.count > 0 {
            endpoint = String(endpoint.dropLast(url.lastPathComponent.count))
        }

        if !endpoint.hasSuffix("/") {
            endpoint.append("/")
        }

        return endpoint
    }

    /// Convenience constructor.
    ///
    /// - Parameters:
    ///   - oAuthToken: The oauth bearer token for the API
    ///   - userAgent: The user agent to use when making http requests.
    ///   - site: The site the API will query
    ///
    convenience init(oAuthToken: String? = nil, userAgent: String? = nil, site: String) {
        let endpoint = WordPressCoreRestApi.baseEndpointForSite(site)
        self.init(oAuthToken: oAuthToken, userAgent: userAgent,
                  backgroundUploads: false,
                  backgroundSessionIdentifier: WordPressComRestApi.defaultBackgroundSessionIdentifier,
                  sharedContainerIdentifier: nil,
                  localeKey: WordPressComRestApi.LocaleKeyDefault,
                  baseUrlString: endpoint)
    }
}
