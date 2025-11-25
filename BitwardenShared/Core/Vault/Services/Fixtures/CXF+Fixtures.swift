// swiftlint:disable:this file_name

import TestHelpers

/// Fixtures for Credential Exchange flows.
enum CXFFixtures {
    /// Fixture to be used on export flow with two basic-auth ciphers.
    static let twoBasicAuthCiphers = TestDataHelpers.loadUTFStringFromJsonBundle(
        resource: "cxfTwoBasicAuthCiphers",
        bundle: .bitwardenShared,
    )
}
