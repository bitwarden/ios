import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherRequestModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(cipher:)` maps the cipher's bank account data into the request model.
    func test_init_bankAccount() {
        let cipher = Cipher.fixture(
            bankAccount: .fixture(
                accountNumber: "123456789",
                accountType: "checking",
                bankContactPhone: "555-0100",
                bankName: "Bitwarden Bank",
                branchNumber: "001",
                iban: "GB33BUKB20201555555555",
                nameOnAccount: "Test User",
                pin: "4321",
                routingNumber: "021000021",
                swiftCode: "BUKBGB22",
            ),
            type: .bankAccount,
        )

        let subject = CipherRequestModel(cipher: cipher)

        XCTAssertEqual(subject.bankAccount?.accountNumber, "123456789")
        XCTAssertEqual(subject.bankAccount?.accountType, "checking")
        XCTAssertEqual(subject.bankAccount?.bankContactPhone, "555-0100")
        XCTAssertEqual(subject.bankAccount?.bankName, "Bitwarden Bank")
        XCTAssertEqual(subject.bankAccount?.branchNumber, "001")
        XCTAssertEqual(subject.bankAccount?.iban, "GB33BUKB20201555555555")
        XCTAssertEqual(subject.bankAccount?.nameOnAccount, "Test User")
        XCTAssertEqual(subject.bankAccount?.pin, "4321")
        XCTAssertEqual(subject.bankAccount?.routingNumber, "021000021")
        XCTAssertEqual(subject.bankAccount?.swiftCode, "BUKBGB22")
    }

    /// `init(cipher:)` leaves the bank account data `nil` when the cipher has none.
    func test_init_bankAccount_nil() {
        let subject = CipherRequestModel(cipher: .fixture(bankAccount: nil))

        XCTAssertNil(subject.bankAccount)
    }

    /// `init(cipher:)` maps the cipher's driver's license data into the request model.
    func test_init_driversLicense() {
        let cipher = Cipher.fixture(
            driversLicense: .fixture(
                dateOfBirth: "1990-01-01",
                expirationDate: "2030-01-01",
                firstName: "Test",
                issueDate: "2020-01-01",
                issuingAuthority: "DMV",
                issuingCountry: "US",
                issuingState: "CA",
                lastName: "User",
                licenseClass: "C",
                licenseNumber: "D1234567",
                middleName: "Q",
            ),
            type: .driversLicense,
        )

        let subject = CipherRequestModel(cipher: cipher)

        XCTAssertEqual(subject.driversLicense?.dateOfBirth, "1990-01-01")
        XCTAssertEqual(subject.driversLicense?.expirationDate, "2030-01-01")
        XCTAssertEqual(subject.driversLicense?.firstName, "Test")
        XCTAssertEqual(subject.driversLicense?.issueDate, "2020-01-01")
        XCTAssertEqual(subject.driversLicense?.issuingAuthority, "DMV")
        XCTAssertEqual(subject.driversLicense?.issuingCountry, "US")
        XCTAssertEqual(subject.driversLicense?.issuingState, "CA")
        XCTAssertEqual(subject.driversLicense?.lastName, "User")
        XCTAssertEqual(subject.driversLicense?.licenseClass, "C")
        XCTAssertEqual(subject.driversLicense?.licenseNumber, "D1234567")
        XCTAssertEqual(subject.driversLicense?.middleName, "Q")
    }

    /// `init(cipher:)` leaves the driver's license data `nil` when the cipher has none.
    func test_init_driversLicense_nil() {
        let subject = CipherRequestModel(cipher: .fixture(driversLicense: nil))

        XCTAssertNil(subject.driversLicense)
    }

    /// `init(cipher:)` maps the cipher's passport data into the request model.
    func test_init_passport() {
        let cipher = Cipher.fixture(
            passport: .fixture(
                birthPlace: "Springfield",
                dateOfBirth: "1990-01-01",
                expirationDate: "2030-01-01",
                givenName: "Test",
                issueDate: "2020-01-01",
                issuingAuthority: "State Dept",
                issuingCountry: "US",
                nationalIdentificationNumber: "N1234567",
                nationality: "American",
                passportNumber: "P1234567",
                passportType: "P",
                sex: "X",
                surname: "User",
            ),
            type: .passport,
        )

        let subject = CipherRequestModel(cipher: cipher)

        XCTAssertEqual(subject.passport?.birthPlace, "Springfield")
        XCTAssertEqual(subject.passport?.dateOfBirth, "1990-01-01")
        XCTAssertEqual(subject.passport?.expirationDate, "2030-01-01")
        XCTAssertEqual(subject.passport?.givenName, "Test")
        XCTAssertEqual(subject.passport?.issueDate, "2020-01-01")
        XCTAssertEqual(subject.passport?.issuingAuthority, "State Dept")
        XCTAssertEqual(subject.passport?.issuingCountry, "US")
        XCTAssertEqual(subject.passport?.nationalIdentificationNumber, "N1234567")
        XCTAssertEqual(subject.passport?.nationality, "American")
        XCTAssertEqual(subject.passport?.passportNumber, "P1234567")
        XCTAssertEqual(subject.passport?.passportType, "P")
        XCTAssertEqual(subject.passport?.sex, "X")
        XCTAssertEqual(subject.passport?.surname, "User")
    }

    /// `init(cipher:)` leaves the passport data `nil` when the cipher has none.
    func test_init_passport_nil() {
        let subject = CipherRequestModel(cipher: .fixture(passport: nil))

        XCTAssertNil(subject.passport)
    }
}
