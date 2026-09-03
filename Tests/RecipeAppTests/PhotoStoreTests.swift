import UIKit
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

    /// A solid-color JPEG of the given pixel size, standing in for a real camera photo.
    private func jpegData(width: CGFloat, height: CGFloat) -> Data {
        // Force scale 1 so the rendered pixel count matches width/height exactly —
        // otherwise this bakes in the simulator's screen scale (e.g. 3x on iPhone 17).
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.jpegData(compressionQuality: 1)!
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

    // MARK: - Downscaling

    func test_save_downscalesOversizedImageToMaxDimension() throws {
        let data = jpegData(width: 4000, height: 3000)

        let filename = try XCTUnwrap(PhotoStore.save(data))
        savedFilenames.append(filename)

        let saved = try XCTUnwrap(UIImage(contentsOfFile: PhotoStore.url(for: filename).path))
        XCTAssertEqual(max(saved.size.width, saved.size.height), 1600, accuracy: 1)
        XCTAssertEqual(saved.size.width / saved.size.height, 4000.0 / 3000.0, accuracy: 0.01)
    }

    func test_save_leavesAlreadySmallImageUntouched() throws {
        let data = jpegData(width: 400, height: 300)

        let filename = try XCTUnwrap(PhotoStore.save(data))
        savedFilenames.append(filename)

        let saved = try XCTUnwrap(UIImage(contentsOfFile: PhotoStore.url(for: filename).path))
        XCTAssertEqual(saved.size, CGSize(width: 400, height: 300))
    }

    func test_save_fallsBackToRawBytesForNonImageData() throws {
        // Confirms the resize path only ever engages for real, decodable images —
        // anything else (like arbitrary test fixtures) round-trips unchanged.
        let data = Data("not a real image".utf8)

        let filename = try XCTUnwrap(PhotoStore.save(data))
        savedFilenames.append(filename)

        let readBack = try Data(contentsOf: PhotoStore.url(for: filename))
        XCTAssertEqual(readBack, data)
    }

    // MARK: - Cached image(for:)

    func test_image_loadsSavedPhoto() throws {
        let filename = try XCTUnwrap(PhotoStore.save(jpegData(width: 100, height: 100)))
        savedFilenames.append(filename)

        XCTAssertNotNil(PhotoStore.image(for: filename))
    }

    func test_image_returnsNilForMissingFile() {
        XCTAssertNil(PhotoStore.image(for: "never-existed.jpg"))
    }

    func test_image_returnsSameCachedInstanceOnRepeatedCalls() throws {
        let filename = try XCTUnwrap(PhotoStore.save(jpegData(width: 100, height: 100)))
        savedFilenames.append(filename)

        let first = try XCTUnwrap(PhotoStore.image(for: filename))
        let second = try XCTUnwrap(PhotoStore.image(for: filename))

        XCTAssertTrue(first === second, "expected the second call to hit the in-memory cache")
    }

    func test_delete_evictsFromCache() throws {
        let filename = try XCTUnwrap(PhotoStore.save(jpegData(width: 100, height: 100)))
        _ = try XCTUnwrap(PhotoStore.image(for: filename))

        PhotoStore.delete(filename)

        XCTAssertNil(PhotoStore.image(for: filename))
    }
}
