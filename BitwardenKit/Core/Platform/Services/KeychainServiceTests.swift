import BitwardenKit
import XCTest

class KeychainServiceTests: BitwardenTestCase {
    // MARK: Tests

    /// Creating an access control with no specific protection or flags results in the correct default values.
    func test_accessControl_default() throws {
        let subject = DefaultKeychainService()

        let accessControl = try subject.accessControl(
            protection: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            for: [],
        )
        var error: Unmanaged<CFError>?
        let expected = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [],
            &error,
        )
        XCTAssertEqual(accessControl, expected)
    }

    /// Specifying `.biometryCurrentSet` access control flag is reflected in the access control.
    func test_accessControl_withBiometrics() throws {
        let subject = DefaultKeychainService()

        let accessControl = try subject.accessControl(
            protection: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            for: .biometryCurrentSet,
        )
        var error: Unmanaged<CFError>?
        let expected = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error,
        )
        XCTAssertEqual(accessControl, expected)
    }

    /// Specifying a custom protection level is reflected in the access control.
    func test_accessControl_withProtection() throws {
        let subject = DefaultKeychainService()

        let accessControl = try subject.accessControl(
            protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            for: [],
        )
        var error: Unmanaged<CFError>?
        let expected = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            [],
            &error,
        )
        XCTAssertEqual(accessControl, expected)
    }
}
