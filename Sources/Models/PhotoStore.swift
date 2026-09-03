import Foundation
import UIKit

enum PhotoStore {
    /// Longest edge a saved photo is allowed to keep. Camera-roll photos come in at
    /// several thousand pixels and several MB; nothing in this app displays a photo
    /// larger than a full-bleed hero, so anything above this is pure decode cost paid
    /// on every scroll and render for no visible benefit.
    private static let maxDimension: CGFloat = 1600

    /// In-memory cache so scrolling a grid/list doesn't re-decode the same file from
    /// disk on every render pass — only ever pays the decode cost once per filename.
    private static let cache = NSCache<NSString, UIImage>()

    static var directory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("RecipePhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    @discardableResult
    static func save(_ data: Data) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let payload = downscaledJPEG(from: data) ?? data
        do {
            try payload.write(to: url(for: filename))
            return filename
        } catch {
            return nil
        }
    }

    static func delete(_ filename: String) {
        cache.removeObject(forKey: filename as NSString)
        try? FileManager.default.removeItem(at: url(for: filename))
    }

    /// Loads (and caches) the photo for `filename`, or nil if it doesn't exist / isn't a
    /// valid image. Prefer this over reading `url(for:)` directly in a view body.
    static func image(for filename: String) -> UIImage? {
        let key = filename as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = UIImage(contentsOfFile: url(for: filename).path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    /// Re-encodes `data` at a capped resolution if it's a real, oversized image. Returns
    /// nil (falling back to the original bytes as-is) for anything already small enough,
    /// or that isn't decodable as an image at all.
    private static func downscaledJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else { return nil }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        // JPEG has no points-vs-pixels concept, so force scale 1 — otherwise the renderer
        // bakes in the current device/simulator's screen scale and the file balloons.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.85)
    }
}
