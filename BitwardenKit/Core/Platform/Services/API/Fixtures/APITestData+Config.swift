import Foundation
import TestHelpers

public extension APITestData {
    /// A valid server configuration to produce a `ConfigResponseModel`.
    static let validServerConfig = loadFromJsonBundle(resource: "ValidServerConfig")
}
