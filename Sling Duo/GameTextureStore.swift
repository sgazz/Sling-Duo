import SpriteKit
import UIKit

/// Scene-owned textures. Data assets avoid UIImage(named:)'s process-wide cache;
/// releasing this store and its nodes drops every app-owned reference.
/// SpriteKit/Metal may defer reclamation of GPU allocations until a later frame.
final class GameTextureStore {
    private struct Region: Hashable {
        let name: String
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
    }
    private var originals: [String: SKTexture] = [:]
    private var regions: [Region: SKTexture] = [:]
    private var generation = 0
    private(set) var activeCave: CaveID?
    var cachedNames: Set<String> { Set(originals.keys) }

    static let sharedNames: Set<String> = Set(["Cyan", "Orange"].flatMap { hero in
        ["Idle", "Anchored", "Pull", "Flight", "Catch", "Miss"].map { "Hero\(hero)\($0)" }
    } + ["DawnheartFragment"])

    static func names(for cave: CaveID) -> Set<String> {
        let background: [String]
        switch cave {
        case .depths: background = ["CaveFar", "CaveMid", "CaveForeground"]
        case .undergroundRiver: background = ["RiverWaterTile", "RiverBankOverlay", "RiverDecorSheet"]
        default:
            let prefix = cave.rawValue.prefix(1).uppercased() + cave.rawValue.dropFirst()
            background = ["\(prefix)BaseTile", "\(prefix)BankOverlay", "\(prefix)DecorSheet"]
        }
        return sharedNames.union(background).union(PlatformArtwork.names(for: cave.platformStyle))
    }

    func activate(cave: CaveID) {
        guard activeCave != cave else { return }
        generation += 1
        activeCave = cave
        let retained = Self.names(for: cave)
        originals = originals.filter { retained.contains($0.key) }
        regions = regions.filter { retained.contains($0.key.name) }
    }

    func texture(named name: String) -> SKTexture {
        if let texture = originals[name] { return texture }
        guard let data = NSDataAsset(name: name + "Texture"), let image = UIImage(data: data.data) else {
            preconditionFailure("Missing or invalid runtime texture: \(name)Texture")
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        originals[name] = texture
        return texture
    }

    func texture(named name: String, rect: CGRect) -> SKTexture {
        let key = Region(name: name, x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
        if let texture = regions[key] { return texture }
        let texture = SKTexture(rect: rect, in: texture(named: name))
        texture.filteringMode = .linear
        regions[key] = texture
        return texture
    }

    func preload(cave: CaveID) async {
        activate(cave: cave)
        let requestedGeneration = generation
        // Let the loading overlay appear before decoding the active package.
        await Task.yield()
        guard !Task.isCancelled, requestedGeneration == generation else { return }
        let textures = Self.names(for: cave).sorted().map { texture(named: $0) }
        await withCheckedContinuation { continuation in
            SKTexture.preload(textures) { continuation.resume() }
        }
        // No cache writes after suspension: a superseding selection or release
        // cannot resurrect the previous cave when its preload completes.
    }

    func release() {
        generation += 1
        activeCave = nil
        regions.removeAll()
        originals.removeAll()
    }
}
