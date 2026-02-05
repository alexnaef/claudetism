import Foundation

struct Preset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var targets: [Target]

    init(id: UUID = UUID(), name: String, targets: [Target]) {
        self.id = id
        self.name = name
        self.targets = targets
    }
}
