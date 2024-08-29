import Foundation

// MARK: - ServerVersion

/// Model that represents the server version.
///
struct ServerVersion: Comparable, Codable {
    // MARK: - Properties

    var version: String

    static func < (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        let lhsComponents = lhs.versionComponents()
        let rhsComponents = rhs.versionComponents()

        for (lhsComponent, rhsComponent) in zip(lhsComponents, rhsComponents) {
            if lhsComponent < rhsComponent {
                return true
            } else if lhsComponent > rhsComponent {
                return false
            }
        }
        return lhsComponents.count < rhsComponents.count
    }

    private func versionComponents() -> [Int] {
        let cleanServerVersion = version.split(separator: "-").first ?? ""
        return cleanServerVersion.split(separator: ".").compactMap { Int($0) }
    }
}
