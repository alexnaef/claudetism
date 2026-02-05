import Foundation

struct AppInfo: Identifiable, Equatable {
    let bundleID: String
    let displayName: String
    let url: URL

    var id: String { bundleID }
}
