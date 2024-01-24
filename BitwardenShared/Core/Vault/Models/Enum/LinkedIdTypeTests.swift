import XCTest

@testable import BitwardenShared

class LinkedIdTypeTests: BitwardenTestCase {
    func test_getLinkedIdType_card() {
        let result = LinkedIdType.getLinkedIdType(for: .card)
        let expected: [LinkedIdType] = [
            .cardCardholderName,
            .cardExpMonth,
            .cardExpYear,
            .cardCode,
            .cardBrand,
            .cardNumber,
        ]
        XCTAssertEqual(result, expected)
    }

    func test_getLinkedIdType_identity() {
        let result = LinkedIdType.getLinkedIdType(for: .identity)
        let expected: [LinkedIdType] = [
            .identityTitle,
            .identityMiddleName,
            .identityAddress1,
            .identityAddress2,
            .identityAddress3,
            .identityCity,
            .identityState,
            .identityPostalCode,
            .identityCountry,
            .identityCompany,
            .identityEmail,
            .identityPhone,
            .identitySsn,
            .identityUsername,
            .identityPassportNumber,
            .identityLicenseNumber,
            .identityFirstName,
            .identityLastName,
            .identityFullName,
        ]
        XCTAssertEqual(result, expected)
    }

    func test_getLinkedIdType_login() {
        let result = LinkedIdType.getLinkedIdType(for: .login)
        let expected: [LinkedIdType] = [
            .loginUsername,
            .loginPassword,
        ]
        XCTAssertEqual(result, expected)
    }

    func test_getLinkedIdType_secureNote() {
        let result = LinkedIdType.getLinkedIdType(for: .secureNote)
        let expected: [LinkedIdType] = []
        XCTAssertEqual(result, expected)
    }
}
