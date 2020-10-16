import XCTest
@testable import Newspack

class URLTypeHelperTests: XCTestCase {

    let path = "file://folder/example."

    func testUTIFromPathExtension() {
        let jpg = URL(string: path + "jpg")!
        let png = URL(string: path + "png")!
        let gif = URL(string: path + "gif")!
        let bmp = URL(string: path + "bmp")!
        let mp3 = URL(string: path + "mp3")!
        let wav = URL(string: path + "wav")!
        let mov = URL(string: path + "mov")!
        let mp4 = URL(string: path + "mp4")!
        let mpg = URL(string: path + "mpg")!

        XCTAssert(jpg.utiFromPathExtension == "public.jpeg")
        XCTAssert(png.utiFromPathExtension == "public.png")
        XCTAssert(gif.utiFromPathExtension == "com.compuserve.gif")
        XCTAssert(bmp.utiFromPathExtension == "com.microsoft.bmp")
        XCTAssert(mp3.utiFromPathExtension == "public.mp3")
        XCTAssert(wav.utiFromPathExtension == "com.microsoft.waveform-audio")
        XCTAssert(mov.utiFromPathExtension == "com.apple.quicktime-movie")
        XCTAssert(mp4.utiFromPathExtension == "public.mpeg-4")
        XCTAssert(mpg.utiFromPathExtension == "public.mpeg")
    }

    func testMimeType() {
        let jpg = URL(string: path + "jpg")!
        let png = URL(string: path + "png")!
        let gif = URL(string: path + "gif")!
        let bmp = URL(string: path + "bmp")!
        let mp3 = URL(string: path + "mp3")!
        let wav = URL(string: path + "wav")!
        let mov = URL(string: path + "mov")!
        let mp4 = URL(string: path + "mp4")!
        let mpg = URL(string: path + "mpg")!

        XCTAssert(jpg.mimeType == "image/jpeg")
        XCTAssert(png.mimeType == "image/png")
        XCTAssert(gif.mimeType == "image/gif")
        XCTAssert(bmp.mimeType == "image/bmp")
        XCTAssert(mp3.mimeType == "audio/mpeg")
        XCTAssert(wav.mimeType == "audio/vnd.wave")
        XCTAssert(mov.mimeType == "video/quicktime")
        XCTAssert(mp4.mimeType == "video/mp4")
        XCTAssert(mpg.mimeType == "video/mpeg")
    }

    func testIsImage() {
        XCTAssertTrue(URL(string: path + "jpg")!.isImage)
        XCTAssertTrue(URL(string: path + "gif")!.isImage)
        XCTAssertTrue(URL(string: path + "png")!.isImage)
        XCTAssertTrue(URL(string: path + "bmp")!.isImage)
        XCTAssertFalse(URL(string: path + "txt")!.isImage)
        XCTAssertFalse(URL(string: path + "mov")!.isImage)
        XCTAssertFalse(URL(string: path + "mp3")!.isImage)
        XCTAssertFalse(URL(string: path + "pdf")!.isImage)
    }

    func testIsVideo() {
        XCTAssertTrue(URL(string: path + "mov")!.isVideo)
        XCTAssertTrue(URL(string: path + "mp4")!.isVideo)
        XCTAssertTrue(URL(string: path + "mpeg")!.isVideo)
        XCTAssertFalse(URL(string: path + "txt")!.isVideo)
        XCTAssertFalse(URL(string: path + "jpg")!.isVideo)
        XCTAssertFalse(URL(string: path + "mp3")!.isVideo)
        XCTAssertFalse(URL(string: path + "pdf")!.isVideo)
    }

    func testIsAudio() {
        XCTAssertTrue(URL(string: path + "mp3")!.isAudio)
        XCTAssertTrue(URL(string: path + "wav")!.isAudio)
        XCTAssertFalse(URL(string: path + "txt")!.isAudio)
        XCTAssertFalse(URL(string: path + "mov")!.isAudio)
        XCTAssertFalse(URL(string: path + "png")!.isAudio)
        XCTAssertFalse(URL(string: path + "pdf")!.isAudio)
    }

    func testIsPDF() {
        XCTAssertTrue(URL(string: path + "pdf")!.isPDF)
        XCTAssertFalse(URL(string: path + "wav")!.isPDF)
        XCTAssertFalse(URL(string: path + "txt")!.isPDF)
        XCTAssertFalse(URL(string: path + "jpg")!.isPDF)
        XCTAssertFalse(URL(string: path + "mov")!.isPDF)
    }

}
