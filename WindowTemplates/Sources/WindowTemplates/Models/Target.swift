import Foundation

struct Target: Identifiable, Codable, Equatable {
    var id: UUID
    var appBundleID: String
    var rect: NormalizedRect

    init(id: UUID = UUID(), appBundleID: String, rect: NormalizedRect) {
        self.id = id
        self.appBundleID = appBundleID
        self.rect = rect
    }
}
