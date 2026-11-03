import SpriteKit
import UIKit

/// All authoring coordinates live here rather than in rendering classes.
/// Crops/pivots use top-left normalized master coordinates; decor UVs use bottom-left.
enum VisualManifest {
    struct Entry: Decodable {
        let sourcePixels: [CGFloat]
        let runtimePixels: [CGFloat]
        let crop: [CGFloat]?
        let pivot: [CGFloat]?
        let landingLine: CGFloat?
        let regions: [String: [CGFloat]]
        var pixels: CGSize { CGSize(width: sourcePixels[0], height: sourcePixels[1]) }
        var cropRect: CGRect {
            let c = crop!
            return CGRect(x: c[0] * pixels.width, y: c[1] * pixels.height,
                          width: c[2] * pixels.width, height: c[3] * pixels.height)
        }
    }
    private struct Document: Decodable {
        let version: Int
        let textures: [String: Entry]
    }
    struct HeroFrame {
        let name: String
        let pixels: CGSize
        let crop: CGRect
        let beltY: CGFloat
        let beltX: CGFloat
    }
    private static let document: Document = {
        guard let data = NSDataAsset(name: "VisualManifest"),
              let manifest = try? JSONDecoder().decode(Document.self, from: data.data),
              manifest.version == 1 else { preconditionFailure("Invalid VisualManifest") }
        return manifest
    }()
    static func entry(_ name: String) -> Entry {
        guard let entry = document.textures[name] else { preconditionFailure("Missing visual metadata: \(name)") }
        return entry
    }
    static func hero(_ name: String) -> HeroFrame {
        let e = entry(name)
        return HeroFrame(name: name, pixels: e.pixels, crop: e.cropRect,
                         beltY: e.pivot![1] * e.pixels.height,
                         beltX: e.pivot![0] * e.pixels.width)
    }
    static func region(_ name: String, in texture: String) -> CGRect {
        guard let r = entry(texture).regions[name] else { preconditionFailure("Missing decor region: \(texture)/\(name)") }
        return CGRect(x: r[0], y: r[1], width: r[2], height: r[3])
    }
}
