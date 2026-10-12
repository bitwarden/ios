import Foundation
import TestHelpers

public extension APITestData {
    /// A valid server configuration to produce a `ConfigResponseModel`.
    static let validServerConfig = loadFromJsonBundle(resource: "ValidServerConfig")

    /// A valid server configuration with `disableUserRegistration` set to `true`.
    static let validServerConfigDisableRegistration = loadFromJsonBundle(
        resource: "ValidServerConfigDisableRegistration",
    )
}
