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
        let clampedW = max(0, min(1, width))
        let clampedH = max(0, min(1, height))

        return CGRect(
            x: frame.origin.x + frame.size.width * clampedX,
            y: frame.origin.y + frame.size.height * clampedY,
            width: frame.size.width * clampedW,
            height: frame.size.height * clampedH
        )
    }
}
