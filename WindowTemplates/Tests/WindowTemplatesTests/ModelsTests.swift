import XCTest
@testable import WindowTemplates

final class ModelsTests: XCTestCase {
    func testPresetRoundTrip() throws {
        let preset = Preset(name: "Work", targets: [
            Target(appBundleID: "com.apple.Safari", rect: NormalizedRect(x: 0, y: 0, width: 0.5, height: 1))
        ])
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)
        XCTAssertEqual(preset, decoded)
    }

    func testNormalizedRectMapping() {
        let frame = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let rect = NormalizedRect(x: 0.5, y: 0, width: 0.5, height: 1)
        let mapped = rect.toCGRect(in: frame)
        XCTAssertEqual(mapped.origin.x, 500, accuracy: 0.01)
        XCTAssertEqual(mapped.origin.y, 0, accuracy: 0.01)
        XCTAssertEqual(mapped.size.width, 500, accuracy: 0.01)
        XCTAssertEqual(mapped.size.height, 800, accuracy: 0.01)
    }
}
