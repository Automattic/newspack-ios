import XCTest
@testable import Newspack

class StagedMediaImporterTests: BaseTest {

    func testPurgeStagedMediaFiles() {
        let context = CoreDataManager.shared.mainContext
        let site = ModelFactory.getTestSite(context: context)
        let filename = "TEMP"
        let importer = StagedMediaImporter(site: site)
        guard let directoryPath = importer.directoryPath() else {
            XCTAssert(false)
            return
        }
        let filePath = directoryPath.appendingPathComponent(filename).appendingPathExtension("jpg")
        let fileManager = FileManager.default
        fileManager.createFile(atPath: filePath.path, contents: nil, attributes: nil)

        XCTAssertTrue(fileManager.fileExists(atPath: filePath.path))

        importer.purgeStagedMediaFiles()

        XCTAssertFalse(fileManager.fileExists(atPath: filePath.path))
    }

}
