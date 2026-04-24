import XCTest

@testable import BitwardenShared

class CipherBankAccountModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `CipherBankAccountModel` round-trips through JSON encoding / decoding with all fields
    /// populated.
    func test_codable_roundTrip_populated() throws {
        let original = CipherBankAccountModel(
            accountNumber: "1234567890",
            accountType: .checking,
            bankName: "Bitwarden Bank",
            bankPhone: "555-0100",
            branchNumber: "100",
            iban: "GB82WEST12345698765432",
            nameOnAccount: "Bitwarden User",
            pin: "1234",
            routingNumber: "011000015",
            swiftCode: "BTCBUS33",
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CipherBankAccountModel.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }

    /// `CipherBankAccountModel` round-trips through JSON when all fields are nil.
    func test_codable_roundTrip_empty() throws {
        let original = CipherBankAccountModel()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CipherBankAccountModel.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }

    /// `CipherBankAccountModel` decodes a representative JSON payload from the server.
    func test_decode_serverPayload() throws {
        let json = """
        {
            "accountNumber": "1234567890",
            "accountType": 0,
            "bankName": "Bitwarden Bank",
            "bankPhone": "555-0100",
            "branchNumber": "100",
            "iban": "GB82WEST12345698765432",
            "nameOnAccount": "Bitwarden User",
            "pin": "1234",
            "routingNumber": "011000015",
            "swiftCode": "BTCBUS33"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(CipherBankAccountModel.self, from: data)

        XCTAssertEqual(decoded.accountNumber, "1234567890")
        XCTAssertEqual(decoded.accountType, .checking)
        XCTAssertEqual(decoded.bankName, "Bitwarden Bank")
        XCTAssertEqual(decoded.bankPhone, "555-0100")
        XCTAssertEqual(decoded.branchNumber, "100")
        XCTAssertEqual(decoded.iban, "GB82WEST12345698765432")
        XCTAssertEqual(decoded.nameOnAccount, "Bitwarden User")
        XCTAssertEqual(decoded.pin, "1234")
        XCTAssertEqual(decoded.routingNumber, "011000015")
        XCTAssertEqual(decoded.swiftCode, "BTCBUS33")
    }

    /// `CipherBankAccountModel` decodes when optional fields are missing.
    func test_decode_missingOptionalFields() throws {
        let json = """
        {
            "bankName": "Bitwarden Bank"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(CipherBankAccountModel.self, from: data)

        XCTAssertEqual(decoded.bankName, "Bitwarden Bank")
        XCTAssertNil(decoded.accountNumber)
        XCTAssertNil(decoded.accountType)
        XCTAssertNil(decoded.bankPhone)
        XCTAssertNil(decoded.branchNumber)
        XCTAssertNil(decoded.iban)
        XCTAssertNil(decoded.nameOnAccount)
        XCTAssertNil(decoded.pin)
        XCTAssertNil(decoded.routingNumber)
        XCTAssertNil(decoded.swiftCode)
    }
}
