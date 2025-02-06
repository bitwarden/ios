// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - ASAuthorizationPublicKeyCredentialDescriptorExtensionTests

// swiftlint:disable:next type_name
class ASAuthorizationPublicKeyCredentialDescriptorExtensionTests: BitwardenTestCase {
    // MARK: Tests

    /// `toPublicKeyCredentialDescriptor()` converts a `ASAuthorizationPublicKeyCredentialDescriptor`
    /// into a `PublicKeyCredentialDescriptor`.
    func test_toPublicKeyCredentialDescriptor() {
        let data = Data(capacity: 16)
        let asDescriptor = MockASAuthorizationPublicKeyCredentialDescriptor(credentialId: data)
        let descriptor = asDescriptor.toPublicKeyCredentialDescriptor()
        XCTAssertEqual(asDescriptor.credentialID, descriptor.id)
        XCTAssertEqual(descriptor.ty, "public-key")
        XCTAssertNil(descriptor.transports)
    }
}

// MARK: - MockASAuthorizationPublicKeyCredentialDescriptor

/// A mock of `ASAuthorizationPublicKeyCredentialDescriptor`.
class MockASAuthorizationPublicKeyCredentialDescriptor: NSObject, ASAuthorizationPublicKeyCredentialDescriptor {
    // swiftlint:disable:previous type_name

    // MARK: Properties

    static var supportsSecureCoding = false

    var credentialID: Data

    // MARK: Init

    init(credentialId: Data) {
        credentialID = credentialId
    }

    required init?(coder: NSCoder) {
        credentialID = Data(capacity: 16)
    }

    // MARK: Methods

    func copy(with zone: NSZone? = nil) -> Any {
        false
    }

    func encode(with coder: NSCoder) {
        // No-op
    }
}
