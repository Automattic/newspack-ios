import Foundation
import WordPressKit

/// Media endpoint wrangling
///
class MediaServiceRemote: ServiceRemoteCoreRest {

    func fetchMedia(for mediaIDs: [Int64], onComplete: @escaping (_ mediaItems: [RemoteMedia]?, _ error: Error?) -> Void) {
        let page = 1
        let perPage = 100

        var fetchError: Error?
        var items = [RemoteMedia]()

        let dispatchGroup = DispatchGroup()

        // Sync all media. Max request size is 100 items so split the IDs into chunks and make multiple requests.
        let chunks = mediaIDs.chunked(into: perPage)
        for chunk in chunks {

            let ids = chunk.map { (item) -> String in
                String(item)
            }.joined(separator: ",")

            let filter = ["id": ids] as [String: AnyObject]
            let params = [
                "_fields": "id,date_gmt,media_details,mime_type,modified_gmt,source_url",
                "page": page,
                "per_page": perPage
            ] as [String: AnyObject]
            let parameters = params.mergedWith(filter)

            dispatchGroup.enter()
            api.GET("media", parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
                let array = response as! [[String: AnyObject]]
                items.append(contentsOf: self.remoteMediaArrayFromResponse(response: array))
                dispatchGroup.leave()

            }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                fetchError = error
                dispatchGroup.leave()
            })
        }

        dispatchGroup.notify(queue: .main) {
            if let error = fetchError {
                onComplete(nil, error)
            } else {
                onComplete(items, nil)
            }
        }
    }

    /// Fetch media items for the specified page.
    ///
    /// - Parameters:
    ///   - filter: A dictionary that identifies a subset of ids to fetch.
    ///   - page: The page to fetch.
    ///   - perPage: The number of items per page.
    ///
    func fetchMediaItems(filter:[String: AnyObject],
                      page: Int,
                      perPage: Int,
                      onComplete: @escaping (_ mediaItems: [RemoteMediaItem]?, _ error: Error?) -> Void) {
        let params = [
            "_fields": "id,date_gmt,media_details,mime_type,modified_gmt,source_url",
            "page": page,
            "per_page": perPage
        ] as [String: AnyObject]
        let parameters = params.mergedWith(filter)

        api.GET("media", parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let array = response as! [[String: AnyObject]]
            let items = self.remoteItemsFromResponse(response: array)

            onComplete(items, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
        })
    }

    /// Fetch the specified media from the specified site
    ///
    /// - Parameters:
    ///   - mediaID: The ID of the media to fetch.
    ///
    func fetchMedia(mediaID: Int64, onComplete: @escaping (_ media: RemoteMedia?, _ error: Error?) -> Void) {
        let parameters = ["context": "edit"] as [String: AnyObject]
        let path = "media/\(mediaID)"

        api.GET(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let media = self.remoteMediaFromResponse(response: dict)

            onComplete(media, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
        })
    }


    /// Create a new media object and upload the associated file.
    ///
    /// - Parameters:
    ///   - mediaParameters: Parameters for the api call, e.g. title, caption, alt_text.
    ///   - localURL: The URL to the local media file that will be uploaded.
    ///   - filename: The filename to use for the uploaded media.  Not guarenteed to be used on the server.
    ///   - mimeType: The mime type of the file to upload.
    ///   - onComplete: Callback to handle success or an error.
    ///
    func createMedia(mediaParameters: [String: AnyObject],
                     localURL: URL,
                     filename: String,
                     mimeType: String,
                     onComplete: @escaping (_ media: RemoteMedia?, _ error: Error?) -> Void) -> Progress? {
        let fileParameterName = "file"
        let filePart = FilePart(parameterName: fileParameterName, url: localURL, filename: filename, mimeType: mimeType)
        let parameters = sanitizeMediaParameters(parameters: mediaParameters)
        let path = "media"
        return api.multipartPOST(path, parameters: parameters, fileParts: [filePart], success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let media = self.remoteMediaFromResponse(response: dict)
            onComplete(media, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
        })

    }

    /// Updates media properties based on the parameters passed. Does not alter the remote file.
    ///
    /// - Parameters:
    ///   - mediaID: The ID of the media item to update.
    ///   - mediaParameters: A dictionary specifying the properties to update, and the values to use.
    ///   - onComplete: A completion call back.
    ///
    func updateMediaProperties(mediaID: Int64, mediaParameters: [String: AnyObject], onComplete: @escaping (_ media: RemoteMedia?, _ error: Error?) -> Void) {
        let parameters = ["context": "edit"] as [String: AnyObject]
        let path = "media/\(mediaID)"
        api.POST(path, parameters: parameters, success: { (response: AnyObject, httpResponse: HTTPURLResponse?) in
            let dict = response as! [String: AnyObject]
            let media = self.remoteMediaFromResponse(response: dict)

            onComplete(media, nil)

        }, failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
            onComplete(nil, error)
        })
    }

    /// Sanitize the passed array of parameters. Removes unsupported parameters.
    ///
    /// - Parameter parameters: A dictionary of parameters to sanitize.
    ///
    func sanitizeMediaParameters(parameters: [String: AnyObject]) -> [String: AnyObject] {
        // filter based on accepted parameters
        let allowedKeys = ["title", "alt_text", "caption"]
        return parameters.filter { (key: String, value: AnyObject) -> Bool in
            return allowedKeys.contains(key)
        }
    }

}

// MARK: - Remote model management.
//
extension MediaServiceRemote {

    /// Formats the response from fetching media items with fields limited to identifying information.
    ///
    /// - Parameter response: The response from the media endpoint
    /// - Returns: An array of RemoteMediaItem objects.
    ///
    func remoteItemsFromResponse(response: [[String: AnyObject]]) -> [RemoteMediaItem] {
        var items = [RemoteMediaItem]()
        for dict in response {
            items.append(RemoteMediaItem(dict: dict))
        }
        return items
    }

    /// Format a media endpoint response into an array of remote media objects.
    ///
    /// - Parameter response: The response from an endpoint.
    /// - Returns: An array of RemoteMedia objects.
    ///
    func remoteMediaArrayFromResponse(response: [[String: AnyObject]]) -> [RemoteMedia] {
        var media = [RemoteMedia]()
        for dict in response {
            media.append(remoteMediaFromResponse(response: dict))
        }
        return media
    }

    /// Formats a remote media object from an api response.
    ///
    /// - Parameter response: The API response for a media object
    /// - Returns: A RemoteMedia instance
    ///
    func remoteMediaFromResponse(response: [String: AnyObject]) -> RemoteMedia {
        return RemoteMedia(dict: response)
    }
}
