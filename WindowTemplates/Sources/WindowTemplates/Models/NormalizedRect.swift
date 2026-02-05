import Foundation
import CoreGraphics

struct NormalizedRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let zero = NormalizedRect(x: 0, y: 0, width: 0, height: 0)

    func toCGRect(in frame: CGRect) -> CGRect {
        let clampedX = max(0, min(1, x))
        let clampedY = max(0, min(1, y))
        let clampedW = max(0, min(1 - clampedX, width))
        let clampedH = max(0, min(1 - clampedY, height))

        let px = (frame.origin.x + frame.size.width * clampedX).rounded(.down)
        let py = (frame.origin.y + frame.size.height * clampedY).rounded(.down)
        let pr = (frame.origin.x + frame.size.width * (clampedX + clampedW)).rounded(.down)
        let pb = (frame.origin.y + frame.size.height * (clampedY + clampedH)).rounded(.down)

        return CGRect(x: px, y: py, width: pr - px, height: pb - py)
    }
}
