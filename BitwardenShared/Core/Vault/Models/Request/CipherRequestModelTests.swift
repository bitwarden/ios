import BitwardenSdk
import Testing

@testable import BitwardenShared

struct CipherRequestModelTests {
    // MARK: Tests

    /// `init(cipher:)` maps the cipher's bank account data into the request model.
    @Test
    func init_bankAccount() {
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

        #expect(subject.bankAccount?.accountNumber == "123456789")
        #expect(subject.bankAccount?.accountType == "checking")
        #expect(subject.bankAccount?.bankContactPhone == "555-0100")
        #expect(subject.bankAccount?.bankName == "Bitwarden Bank")
        #expect(subject.bankAccount?.branchNumber == "001")
        #expect(subject.bankAccount?.iban == "GB33BUKB20201555555555")
        #expect(subject.bankAccount?.nameOnAccount == "Test User")
        #expect(subject.bankAccount?.pin == "4321")
        #expect(subject.bankAccount?.routingNumber == "021000021")
        #expect(subject.bankAccount?.swiftCode == "BUKBGB22")
    }

    /// `init(cipher:)` leaves the bank account data `nil` when the cipher has none.
    @Test
    func init_bankAccount_nil() {
        let subject = CipherRequestModel(cipher: .fixture(bankAccount: nil))

        #expect(subject.bankAccount == nil)
    }

    /// `init(cipher:)` maps the cipher's driver's license data into the request model.
    @Test
    func init_driversLicense() {
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

        #expect(subject.driversLicense?.dateOfBirth == "1990-01-01")
        #expect(subject.driversLicense?.expirationDate == "2030-01-01")
        #expect(subject.driversLicense?.firstName == "Test")
        #expect(subject.driversLicense?.issueDate == "2020-01-01")
        #expect(subject.driversLicense?.issuingAuthority == "DMV")
        #expect(subject.driversLicense?.issuingCountry == "US")
        #expect(subject.driversLicense?.issuingState == "CA")
        #expect(subject.driversLicense?.lastName == "User")
        #expect(subject.driversLicense?.licenseClass == "C")
        #expect(subject.driversLicense?.licenseNumber == "D1234567")
        #expect(subject.driversLicense?.middleName == "Q")
    }

    /// `init(cipher:)` leaves the driver's license data `nil` when the cipher has none.
    @Test
    func init_driversLicense_nil() {
        let subject = CipherRequestModel(cipher: .fixture(driversLicense: nil))

        #expect(subject.driversLicense == nil)
    }

    /// `init(cipher:)` maps the cipher's passport data into the request model.
    @Test
    func init_passport() {
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

        #expect(subject.passport?.birthPlace == "Springfield")
        #expect(subject.passport?.dateOfBirth == "1990-01-01")
        #expect(subject.passport?.expirationDate == "2030-01-01")
        #expect(subject.passport?.givenName == "Test")
        #expect(subject.passport?.issueDate == "2020-01-01")
        #expect(subject.passport?.issuingAuthority == "State Dept")
        #expect(subject.passport?.issuingCountry == "US")
        #expect(subject.passport?.nationalIdentificationNumber == "N1234567")
        #expect(subject.passport?.nationality == "American")
        #expect(subject.passport?.passportNumber == "P1234567")
        #expect(subject.passport?.passportType == "P")
        #expect(subject.passport?.sex == "X")
        #expect(subject.passport?.surname == "User")
    }

    /// `init(cipher:)` leaves the passport data `nil` when the cipher has none.
    @Test
    func init_passport_nil() {
        let subject = CipherRequestModel(cipher: .fixture(passport: nil))

        #expect(subject.passport == nil)
    }
}
