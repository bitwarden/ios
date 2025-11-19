import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var clientService: MockClientService!
    var generatorDataStore: DataStore!
    var subject: GeneratorRepository!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        generatorDataStore = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
        stateService = MockStateService()

        subject = DefaultGeneratorRepository(
            clientService: clientService,
            dataStore: generatorDataStore,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        generatorDataStore = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `addPasswordHistory()` adds a `PasswordHistoryView` to the list of history.
    func test_addPasswordHistory() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let passwordHistory1 = PasswordHistoryView.fixture(password: "PASSWORD")
        try await subject.addPasswordHistory(passwordHistory1)

        let passwordHistory2 = PasswordHistoryView.fixture(password: "PASSWORD2")
        try await subject.addPasswordHistory(passwordHistory2)

        let passwordHistory3 = PasswordHistoryView.fixture(password: "PASSWORD3")
        try await subject.addPasswordHistory(passwordHistory3)

        let results = try generatorDataStore.backgroundContext.fetch(
            PasswordHistoryData.fetchByUserIdRequest(userId: "1"),
        )
        XCTAssertEqual(
            try results.map(PasswordHistory.init),
            [passwordHistory1, passwordHistory2, passwordHistory3].map(PasswordHistory.init),
        )
        XCTAssertEqual(
            clientService.mockVault.clientPasswordHistory.encryptedPasswordHistory,
            [passwordHistory1, passwordHistory2, passwordHistory3],
        )
    }

    /// `addPasswordHistory()` adds a `PasswordHistoryView` to the list of history and limits the
    /// maximum size of the history.
    func test_addPasswordHistory_limitsMaxValues() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let passwords = (0 ... 150).map { index in
            // Manually specifying the date as the index value prevents the instances from
            // getting out of order when sorting by the date.
            PasswordHistoryView.fixture(
                password: index.description,
                lastUsedDate: Date(timeIntervalSince1970: Double(index)),
            )
        }

        for password in passwords {
            try await subject.addPasswordHistory(password)
        }

        XCTAssertEqual(
            try generatorDataStore.backgroundContext
                .count(for: PasswordHistoryData.fetchByUserIdRequest(userId: "1")),
            100,
        )

        let fetchRequest = PasswordHistoryData.fetchByUserIdRequest(userId: "1")
        fetchRequest.sortDescriptors = [PasswordHistoryData.sortByLastUsedDateDescending]
        let results = try generatorDataStore.backgroundContext.fetch(fetchRequest)
        XCTAssertEqual(
            try results.map(PasswordHistory.init),
            passwords.suffix(100).reversed().map(PasswordHistory.init),
        )
    }

    /// `addPasswordHistory()` adds a `PasswordHistoryView` to the list of history and prevents
    /// adding duplicate values at the top of the list.
    func test_addPasswordHistory_preventsDuplicates() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let passwordHistory = PasswordHistoryView.fixture(
            password: "PASSWORD",
            lastUsedDate: Date(timeIntervalSince1970: 1),
        )
        let passwordHistoryDuplicate = PasswordHistoryView.fixture(
            password: "PASSWORD",
            lastUsedDate: Date(timeIntervalSince1970: 2),
        )
        let passwordHistoryOther = PasswordHistoryView.fixture(
            password: "PASSWORD_OTHER",
            lastUsedDate: Date(timeIntervalSince1970: 3),
        )

        try await subject.addPasswordHistory(passwordHistory)
        try await subject.addPasswordHistory(passwordHistoryDuplicate)
        try await subject.addPasswordHistory(passwordHistoryOther)

        let fetchRequest = PasswordHistoryData.fetchByUserIdRequest(userId: "1")
        fetchRequest.sortDescriptors = [PasswordHistoryData.sortByLastUsedDateDescending]
        let results = try generatorDataStore.backgroundContext.fetch(fetchRequest)
        XCTAssertEqual(
            try results.map(PasswordHistory.init),
            [passwordHistoryOther, passwordHistory].map(PasswordHistory.init),
        )
    }

    /// `clearPasswordHistory()` clears the password history list.
    func test_clearPasswordHistory() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let passwords = (0 ..< 5).map { PasswordHistoryView.fixture(password: $0.description) }
        for password in passwords {
            try await subject.addPasswordHistory(password)
        }

        try await subject.clearPasswordHistory()

        XCTAssertEqual(
            try generatorDataStore.backgroundContext
                .count(for: PasswordHistoryData.fetchByUserIdRequest(userId: "1")),
            0,
        )
    }

    /// `generateMasterPassword` returns the generated master password.
    func test_generateMasterPassword() async throws {
        let masterPassword = try await subject.generateMasterPassword()
        XCTAssertEqual(masterPassword, "PASSPHRASE")
        XCTAssertTrue(clientService.mockGeneratorsIsPreAuth)
        XCTAssertEqual(
            clientService.mockGenerators.passphraseGeneratorRequest,
            PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: true,
                includeNumber: true,
            ),
        )
    }

    /// `generatePassphrase` returns the generated passphrase.
    func test_generatePassphrase() async throws {
        let passphrase = try await subject.generatePassphrase(
            settings: PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: false,
                includeNumber: false,
            ),
        )

        XCTAssertEqual(passphrase, "PASSPHRASE")
    }

    /// `generatePassphrase` throws an error if generating a passphrase fails.
    func test_generatePassphrase_error() async {
        struct GeneratePassphraseError: Error, Equatable {}

        clientService.mockGenerators.passphraseResult = .failure(GeneratePassphraseError())

        await assertAsyncThrows(error: GeneratePassphraseError()) {
            _ = try await subject.generatePassphrase(
                settings: PassphraseGeneratorRequest(
                    numWords: 3,
                    wordSeparator: "-",
                    capitalize: false,
                    includeNumber: false,
                ),
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
                minSpecial: nil,
            ),
        )

        XCTAssertEqual(password, "PASSWORD")
    }

    /// `generatePassword` throws an error if generating a password fails.
    func test_generatePassword_error() async {
        struct GeneratePasswordError: Error, Equatable {}

        clientService.mockGenerators.passwordResult = .failure(GeneratePasswordError())

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
                    minSpecial: nil,
                ),
            )
        }
    }

    /// `generateUsername()` returns the generated username.
    func test_generateUsername() async throws {
        let username = try await subject.generateUsername(
            settings: UsernameGeneratorRequest.subaddress(type: .random, email: "user@bitwarden.com"),
        )

        XCTAssertEqual(username, "USERNAME")
    }

    /// `generateUsername` throws an error if generating a username fails.
    func test_generateUsername_error() async {
        struct GenerateUsernameError: Error, Equatable {}

        clientService.mockGenerators.usernameResult = .failure(GenerateUsernameError())

        await assertAsyncThrows(error: GenerateUsernameError()) {
            _ = try await subject.generateUsername(
                settings: UsernameGeneratorRequest.subaddress(type: .random, email: "user@bitwarden.com"),
            )
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

    /// `passwordHistoryPublisher()` returns a publisher that the user's password history as it changes.
    @MainActor
    func test_passwordHistoryPublisher() {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        var passwordHistoryValues = [[PasswordHistoryView]]()
        let task = Task {
            for try await passwordHistory in try await subject.passwordHistoryPublisher() {
                passwordHistoryValues.append(passwordHistory)
            }
        }
        waitFor { passwordHistoryValues.count == 1 }

        let passwordHistory1 = PasswordHistoryView.fixture(password: "PASSWORD")
        Task {
            try await subject.addPasswordHistory(passwordHistory1)
        }
        waitFor { passwordHistoryValues.count == 2 }

        let passwordHistory2 = PasswordHistoryView.fixture(password: "PASSWORD2")
        Task {
            try await subject.addPasswordHistory(passwordHistory2)
        }
        waitFor { passwordHistoryValues.count == 3 }
        task.cancel()

        XCTAssertTrue(passwordHistoryValues[0].isEmpty)
        XCTAssertEqual(passwordHistoryValues[1], [passwordHistory1])
        XCTAssertEqual(passwordHistoryValues[2], [passwordHistory2, passwordHistory1])
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
