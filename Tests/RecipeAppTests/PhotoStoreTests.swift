import XCTest
@testable import RecipeApp

final class PhotoStoreTests: XCTestCase {
    private var savedFilenames: [String] = []

    override func tearDownWithError() throws {
        for filename in savedFilenames {
            PhotoStore.delete(filename)
        }
        savedFilenames = []
    }

    func test_save_writesFileAndReturnsFilename() throws {
        let data = Data("fake jpeg bytes".utf8)

        let filename = try XCTUnwrap(PhotoStore.save(data))
        savedFilenames.append(filename)

        XCTAssertTrue(filename.hasSuffix(".jpg"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: PhotoStore.url(for: filename).path))
    }

    func test_save_roundTripsExactBytes() throws {
        let data = Data("some recipe photo".utf8)

        let filename = try XCTUnwrap(PhotoStore.save(data))
        savedFilenames.append(filename)

        let readBack = try Data(contentsOf: PhotoStore.url(for: filename))
        XCTAssertEqual(readBack, data)
    }

    func test_save_generatesUniqueFilenamesForEachCall() throws {
        let data = Data("photo".utf8)

        let first = try XCTUnwrap(PhotoStore.save(data))
        let second = try XCTUnwrap(PhotoStore.save(data))
        savedFilenames.append(contentsOf: [first, second])

        XCTAssertNotEqual(first, second)
    }

    func test_delete_removesFile() throws {
        let data = Data("photo".utf8)
        let filename = try XCTUnwrap(PhotoStore.save(data))

        PhotoStore.delete(filename)

        XCTAssertFalse(FileManager.default.fileExists(atPath: PhotoStore.url(for: filename).path))
    }

    func test_delete_isSafeForNonexistentFile() {
        // Should not throw or crash even though this file was never created.
        PhotoStore.delete("never-existed.jpg")
    }

    func test_url_isScopedToRecipePhotosDirectory() {
        let url = PhotoStore.url(for: "example.jpg")

        XCTAssertEqual(url.lastPathComponent, "example.jpg")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "RecipePhotos")
    }
}
