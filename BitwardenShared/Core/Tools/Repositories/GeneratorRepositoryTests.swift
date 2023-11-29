import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientGenerators: MockClientGenerators!
    var cryptoService: MockCryptoService!
    var subject: GeneratorRepository!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientGenerators = MockClientGenerators()
        cryptoService = MockCryptoService()
        stateService = MockStateService()

        subject = DefaultGeneratorRepository(
            clientGenerators: clientGenerators,
            cryptoService: cryptoService,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientGenerators = nil
        cryptoService = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `addPasswordHistory()` adds a `PasswordHistoryView` to the list of history, in reverse
    /// chronological order.
    func test_addPasswordHistory() throws {
        var passwordHistoryValues = [PasswordHistoryView]()
        Task {
            for await passwordHistory in subject.passwordHistoryPublisher() {
                passwordHistoryValues = passwordHistory
            }
        }

        let passwordHistory1 = PasswordHistoryView.fixture(password: "PASSWORD")
        Task { try await subject.addPasswordHistory(passwordHistory1) }
        waitFor { passwordHistoryValues.count == 1 }
        XCTAssertEqual(passwordHistoryValues, [passwordHistory1])

        let passwordHistory2 = PasswordHistoryView.fixture(password: "PASSWORD2")
        let passwordHistory3 = PasswordHistoryView.fixture(password: "PASSWORD3")
        Task {
            try await subject.addPasswordHistory(passwordHistory2)
            try await subject.addPasswordHistory(passwordHistory3)
        }
        waitFor { passwordHistoryValues.count == 3 }
        XCTAssertEqual(passwordHistoryValues, [passwordHistory3, passwordHistory2, passwordHistory1])
    }

    /// `addPasswordHistory()` adds a `PasswordHistoryView` to the list of history and limits the
    /// maximum size of the history.
    func test_addPasswordHistory_limitsMaxValues() throws {
        var passwordHistoryValues = [PasswordHistoryView]()
        Task {
            for await passwordHistory in subject.passwordHistoryPublisher() {
                passwordHistoryValues = passwordHistory
            }
        }

        let passwords = (0 ... 150).map { PasswordHistoryView.fixture(password: $0.description) }

        Task {
            for password in passwords {
                try await subject.addPasswordHistory(password)
            }
        }

        waitFor { passwordHistoryValues.first == passwords.last }
        XCTAssertEqual(passwordHistoryValues, passwords.suffix(100).reversed())
    }

    /// `addPasswordHistory()` adds a `PasswordHistoryView` to the list of history and prevents
    /// adding duplicate values at the top of the list.
    func test_addPasswordHistory_preventsDuplicates() throws {
        var passwordHistoryValues = [PasswordHistoryView]()
        Task {
            for await passwordHistory in subject.passwordHistoryPublisher() {
                passwordHistoryValues = passwordHistory
            }
        }

        let passwordHistory = PasswordHistoryView.fixture(password: "PASSWORD")
        let passwordHistoryDuplicate = PasswordHistoryView.fixture(password: "PASSWORD")
        let passwordHistoryOther = PasswordHistoryView.fixture(password: "PASSWORD_OTHER")

        Task {
            try await subject.addPasswordHistory(passwordHistory)
            try await subject.addPasswordHistory(passwordHistoryDuplicate)
            try await subject.addPasswordHistory(passwordHistoryOther)
        }

        waitFor { passwordHistoryValues.count == 2 }
        XCTAssertEqual(passwordHistoryValues, [passwordHistoryOther, passwordHistory])
    }

    /// `clearPasswordHistory()` clears the password history list.
    func test_clearPasswordHistory() throws {
        var passwordHistoryValues = [PasswordHistoryView]()
        Task {
            for await passwordHistory in subject.passwordHistoryPublisher() {
                passwordHistoryValues = passwordHistory
            }
        }

        let passwords = (0 ..< 5).map { PasswordHistoryView.fixture(password: $0.description) }

        Task {
            for password in passwords {
                try await subject.addPasswordHistory(password)
            }
        }

        waitFor { passwordHistoryValues.count == 5 }

        Task { await subject.clearPasswordHistory() }

        waitFor { passwordHistoryValues.isEmpty }
        XCTAssertTrue(passwordHistoryValues.isEmpty)
    }

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

    /// `generateUsernamePlusAddressedEmail` returns the generated plus addressed email.
    func test_generateUsernamePlusAddressedEmail() async throws {
        var email = try await subject.generateUsernamePlusAddressedEmail(email: "user@bitwarden.com")
        XCTAssertEqual(email, "user+ku5eoyi3@bitwarden.com")
        XCTAssertEqual(cryptoService.randomStringLength, 8)

        email = try await subject.generateUsernamePlusAddressedEmail(email: "user@bit@warden.com")
        XCTAssertEqual(email, "user+ku5eoyi3@bit@warden.com")

        cryptoService.randomStringResult = .success("abcd0123")
        email = try await subject.generateUsernamePlusAddressedEmail(email: "user@bitwarden.com")
        XCTAssertEqual(email, "user+abcd0123@bitwarden.com")
    }

    /// `generateUsernamePlusAddressedEmail` returns "-" if there aren't enough characters entered.
    func test_generateUsernamePlusAddressedEmail_tooFewCharacters() async throws {
        var email = try await subject.generateUsernamePlusAddressedEmail(email: "")
        XCTAssertEqual(email, "-")

        email = try await subject.generateUsernamePlusAddressedEmail(email: "ab")
        XCTAssertEqual(email, "-")
    }

    /// `generateUsernamePlusAddressedEmail` returns the email with no changes if it doesn't contain
    /// an '@' symbol.
    func test_generateUsernamePlusAddressedEmail_missingAt() async throws {
        var email = try await subject.generateUsernamePlusAddressedEmail(email: "abc")
        XCTAssertEqual(email, "abc")

        email = try await subject.generateUsernamePlusAddressedEmail(email: "user")
        XCTAssertEqual(email, "user")

        email = try await subject.generateUsernamePlusAddressedEmail(email: "bitwarden.com")
        XCTAssertEqual(email, "bitwarden.com")
    }

    /// `generateUsernamePlusAddressedEmail` returns the email with no changes if the '@' symbol is
    /// the first or last character.
    func test_generateUsernamePlusAddressedEmail_atFirstOrLast() async throws {
        var email = try await subject.generateUsernamePlusAddressedEmail(email: "@bitwarden.com")
        XCTAssertEqual(email, "@bitwarden.com")

        email = try await subject.generateUsernamePlusAddressedEmail(email: "user@")
        XCTAssertEqual(email, "user@")
    }

    /// `generateUsernamePlusAddressedEmail` throws an error if generating a username fails.
    func test_generateUsernamePlusAddressedEmail_error() async {
        cryptoService.randomStringResult = .failure(CryptoServiceError.randomNumberGenerationFailed(-1))

        await assertAsyncThrows(error: CryptoServiceError.randomNumberGenerationFailed(-1)) {
            _ = try await subject.generateUsernamePlusAddressedEmail(email: "user@bitwarden.com")
        }
    }

    /// `getPasswordGenerationOptions` returns the saved password generation options for the active account.
    func test_getPasswordGenerationOptions() async throws {
        let options = PasswordGenerationOptions(length: 30)

        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.passwordGenerationOptions = [account.profile.userId: options]

        let fetchedOptions = try await subject.getPasswordGenerationOptions()

        XCTAssertEqual(fetchedOptions, options)
    }

    /// `getPasswordGenerationOptions` returns an empty set of options if they haven't previously
    /// been saved for the active account.
    func test_getPasswordGenerationOptions_notSet() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        let fetchedOptions = try await subject.getPasswordGenerationOptions()

        XCTAssertEqual(fetchedOptions, PasswordGenerationOptions())
    }

    /// `getUsernameGenerationOptions` returns the saved username generation options for the active account.
    func test_getUsernameGenerationOptions() async throws {
        let options = UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com")

        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.usernameGenerationOptions = [account.profile.userId: options]

        let fetchedOptions = try await subject.getUsernameGenerationOptions()

        XCTAssertEqual(fetchedOptions, options)
    }

    /// `getUsernameGenerationOptions` returns the saved username generation options and doesn't
    /// override a previously saved email.
    func test_getUsernameGenerationOptions_emailSet() async throws {
        let options = UsernameGenerationOptions(plusAddressedEmail: "example@bitwarden.com")

        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.usernameGenerationOptions = [account.profile.userId: options]

        let fetchedOptions = try await subject.getUsernameGenerationOptions()

        XCTAssertEqual(fetchedOptions, options)
    }

    /// `getUsernameGenerationOptions` throws an error if there isn't an active account.
    func test_getUsernameGenerationOptions_noAccount() async {
        stateService.activeAccount = nil

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getUsernameGenerationOptions()
        }
    }

    /// `getUsernameGenerationOptions` returns an empty set of options, pre-populated with the
    /// users email if they haven't previously been saved for the active account.
    func test_getUsernameGenerationOptions_notSet() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        let fetchedOptions = try await subject.getUsernameGenerationOptions()

        XCTAssertEqual(fetchedOptions, UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com"))
    }

    /// `setPasswordGenerationOptions` sets the password generation options for the active account.
    func test_setPasswordGenerationOptions() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        let options = PasswordGenerationOptions(length: 30)

        try await subject.setPasswordGenerationOptions(options)

        XCTAssertEqual(stateService.passwordGenerationOptions, [account.profile.userId: options])
    }

    /// `setUsernameGenerationOptions` sets the username generation options for the active account.
    func test_setUsernameGenerationOptions() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        let options = UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com")

        try await subject.setUsernameGenerationOptions(options)

        XCTAssertEqual(stateService.usernameGenerationOptions, [account.profile.userId: options])
    }
}
