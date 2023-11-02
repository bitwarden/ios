import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientGenerators: MockClientGenerators!
    var subject: GeneratorRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientGenerators = MockClientGenerators()

        subject = DefaultGeneratorRepository(clientGenerators: clientGenerators)
    }

    override func tearDown() {
        super.tearDown()

        clientGenerators = nil
        subject = nil
    }

    // MARK: Tests

    /// `generatePassphrase` returns the generated passphrase.
    func test_generatePassphrase() async throws {
        let passphrase = try await subject.generatePassphrase(
            settings: PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: false,
                includeNumber: false
            )
        )

        XCTAssertEqual(passphrase, "PASSPHRASE")
    }

    /// `generatePassphrase` throws an error if generating a passphrase fails.
    func test_generatePassphrase_error() async {
        struct GeneratePassphraseError: Error, Equatable {}

        clientGenerators.passphraseResult = .failure(GeneratePassphraseError())

        await assertAsyncThrows(error: GeneratePassphraseError()) {
            _ = try await subject.generatePassphrase(
                settings: PassphraseGeneratorRequest(
                    numWords: 3,
                    wordSeparator: "-",
                    capitalize: false,
                    includeNumber: false
                )
            )
        }
    }

    /// `generatePassword` returns the generated password.
    func test_generatePassword() async throws {
        let password = try await subject.generatePassword(
            settings: PasswordGeneratorRequest(
                lowercase: true,
                uppercase: true,
                numbers: true,
                special: true,
                length: 12,
                avoidAmbiguous: false,
                minLowercase: nil,
                minUppercase: nil,
                minNumber: nil,
                minSpecial: nil
            )
        )

        XCTAssertEqual(password, "PASSWORD")
    }

    /// `generatePassword` throws an error if generating a password fails.
    func test_generatePassword_error() async {
        struct GeneratePasswordError: Error, Equatable {}

        clientGenerators.passwordResult = .failure(GeneratePasswordError())

        await assertAsyncThrows(error: GeneratePasswordError()) {
            _ = try await subject.generatePassword(
                settings: PasswordGeneratorRequest(
                    lowercase: true,
                    uppercase: true,
                    numbers: true,
                    special: true,
                    length: 12,
                    avoidAmbiguous: false,
                    minLowercase: nil,
                    minUppercase: nil,
                    minNumber: nil,
                    minSpecial: nil
                )
            )
        }
    }
}
