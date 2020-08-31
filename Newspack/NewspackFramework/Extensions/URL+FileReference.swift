import Foundation

extension URL {
    /// This is a work around to an issue where Swift URL instances will not
    /// return a fileReferenceURL. See the thread (and answer) at:
    /// https://bugs.swift.org/browse/SR-2728?focusedCommentId=22388&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-22388
    ///
    /// - Returns: An NSURL or nil if self is not a file URL.
    ///
    public func getFileReferenceURL() -> NSURL? {
        return (self as NSURL).perform(#selector(NSURL.fileReferenceURL))?.takeUnretainedValue() as? NSURL
    }
}
