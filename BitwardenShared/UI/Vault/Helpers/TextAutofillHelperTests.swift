import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - TextAutofillHelperTests

@available(iOS 18.0, *)
class TextAutofillHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var userVerificationHelper: MockUserVerificationHelper!
    var subject: TextAutofillHelper!
    var textAutofillHelperDelegate: MockTextAutofillHelperDelegate!
    var textAutofillOptionsHelperFactory: MockTextAutofillOptionsHelperFactory!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        userVerificationHelper = MockUserVerificationHelper()
        vaultRepository = MockVaultRepository()
        textAutofillHelperDelegate = MockTextAutofillHelperDelegate()
        textAutofillOptionsHelperFactory = MockTextAutofillOptionsHelperFactory()

        subject = DefaultTextAutofillHelper(
            errorReporter: errorReporter,
            eventService: eventService,
            textAutofillOptionsHelperFactory: textAutofillOptionsHelperFactory,
            vaultRepository: vaultRepository
        )
        subject.setTextAutofillHelperDelegate(textAutofillHelperDelegate)
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        eventService = nil
        userVerificationHelper = nil
        subject = nil
        textAutofillOptionsHelperFactory = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `handleCipherForAutofill(cipherView:)` shows options
    /// and user selects one of them autofilling it.
    @MainActor
    func test_handleCipherForAutofill_optionChosenAndAutofill() async throws {
        let optionsHelper = MockTextAutofillOptionsHelper()
        optionsHelper.getTextAutofillOptionsResult = [
            ("Option 1", "Value 1"),
            ("Option 2", "Value 2"),
        ]
        textAutofillOptionsHelperFactory.createResult = optionsHelper
        vaultRepository.fetchCipherResult = .success(.fixture())

        let task = Task {
            try await subject.handleCipherForAutofill(cipherListView: CipherListView.fixture())
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !textAutofillHelperDelegate.alertsShown.isEmpty
        }

        let alert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown.first)
        XCTAssertEqual(alert.title, Localizations.autofill)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions[0].title, "Option 1")
        XCTAssertEqual(alert.alertActions[1].title, "Option 2")
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        try await alert.tapAction(title: "Option 1")

        XCTAssertEqual(textAutofillHelperDelegate.completeTextRequestText, "Value 1")
    }

    /// `handleCipherForAutofill(cipherView:)` with no options alerts the user that there
    /// is nothing available to autofill.
    @MainActor
    func test_handleCipherForAutofill_noOptions() async throws {
        let optionsHelper = MockTextAutofillOptionsHelper()
        optionsHelper.getTextAutofillOptionsResult = []
        textAutofillOptionsHelperFactory.createResult = optionsHelper
        vaultRepository.fetchCipherResult = .success(.fixture(
            name: "Cipher 1"
        ))

        let task = Task {
            try await subject.handleCipherForAutofill(cipherListView: CipherListView.fixture(id: "1", name: "Cipher 1"))
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !textAutofillHelperDelegate.alertsShown.isEmpty
        }

        let alert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown.first)
        XCTAssertEqual(alert.title, "Cipher 1")
        XCTAssertEqual(alert.message, Localizations.nothingAvailableToAutofill)
    }

    /// `handleCipherForAutofill(cipherView:)` shows options
    /// and user selects TOTP of them autofilling it.
    @MainActor
    func test_handleCipherForAutofill_optionChosenTOTP() async throws {
        let optionsHelper = MockTextAutofillOptionsHelper()
        optionsHelper.getTextAutofillOptionsResult = [
            ("Option 1", "Value 1"),
            (Localizations.verificationCode, "123456"),
        ]
        textAutofillOptionsHelperFactory.createResult = optionsHelper
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(totp: "123456")
        ))

        vaultRepository.refreshTOTPCodeResult =
            .success(
                LoginTOTPState.codeKeyPair(
                    TOTPCodeModel(
                        code: "456789",
                        codeGenerationDate: .now,
                        period: 30
                    ),
                    key: TOTPKeyModel(
                        authenticatorKey: "123456"
                    )
                )
            )

        let task = Task {
            try await subject.handleCipherForAutofill(
                cipherListView: CipherListView.fixture(
                    login: .fixture(totp: "123456")
                )
            )
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !textAutofillHelperDelegate.alertsShown.isEmpty
        }

        let alert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown.first)
        XCTAssertEqual(alert.title, Localizations.autofill)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions[0].title, "Option 1")
        XCTAssertEqual(alert.alertActions[1].title, Localizations.verificationCode)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.verificationCode)

        XCTAssertEqual(textAutofillHelperDelegate.completeTextRequestText, "456789")
    }

    /// `handleCipherForAutofill(cipherView:)` shows options
    /// and user selects TOTP of them autofilling it but throws when refreshing the TOTP Code.
    @MainActor
    func test_handleCipherForAutofill_optionChosenTOTPThrwos() async throws {
        let optionsHelper = MockTextAutofillOptionsHelper()
        optionsHelper.getTextAutofillOptionsResult = [
            ("Option 1", "Value 1"),
            (Localizations.verificationCode, "123456"),
        ]
        textAutofillOptionsHelperFactory.createResult = optionsHelper

        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(totp: "123456")
        ))
        vaultRepository.refreshTOTPCodeResult = .failure(BitwardenTestError.example)

        let task = Task {
            try await subject.handleCipherForAutofill(
                cipherListView: CipherListView.fixture(
                    login: .fixture(totp: "123456")
                )
            )
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !textAutofillHelperDelegate.alertsShown.isEmpty
        }

        let alert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown.first)
        XCTAssertEqual(alert.title, Localizations.autofill)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions[0].title, "Option 1")
        XCTAssertEqual(alert.alertActions[1].title, Localizations.verificationCode)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.verificationCode)

        let errorAlert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown[1])
        XCTAssertEqual(errorAlert.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(errorAlert.message, Localizations.failedToGenerateVerificationCode)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertNil(textAutofillHelperDelegate.completeTextRequestText)
    }

    /// `handleCipherForAutofill(cipherView:)` shows options with custom fields
    /// and user selects one custom field to autofill it.
    @MainActor
    func test_handleCipherForAutofill_optionsWithCustomFields() async throws {
        let optionsHelper = MockTextAutofillOptionsHelper()
        optionsHelper.getTextAutofillOptionsResult = [
            ("Option 1", "Value 1"),
            ("Option 2", "Value 2"),
        ]
        textAutofillOptionsHelperFactory.createResult = optionsHelper
        vaultRepository.fetchCipherResult = .success(.fixture(
            fields: [
                .fixture(name: "Field 1", value: "Custom Value 1", type: .text),
                .fixture(name: "Field 2", value: "Custom Value 2", type: .hidden),
                .fixture(name: "Field 3", value: nil, type: .text),
                .fixture(name: nil, value: "Something", type: .text),
                .fixture(name: nil, value: nil, type: .text),
            ],
            id: "1",
            viewPassword: true
        ))

        let task = Task {
            try await subject.handleCipherForAutofill(
                cipherListView: CipherListView.fixture(
                    id: "1",
                    viewPassword: true
                )
            )
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !textAutofillHelperDelegate.alertsShown.isEmpty
        }

        let alert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown.first)
        XCTAssertEqual(alert.title, Localizations.autofill)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions[0].title, "Option 1")
        XCTAssertEqual(alert.alertActions[1].title, "Option 2")
        XCTAssertEqual(alert.alertActions[2].title, Localizations.customFields)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.customFields)

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return textAutofillHelperDelegate.alertsShown.count == 2
        }

        let customFieldsAlert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown[1])
        XCTAssertEqual(customFieldsAlert.title, Localizations.autofill)
        XCTAssertNil(customFieldsAlert.message)
        XCTAssertEqual(customFieldsAlert.alertActions[0].title, "Field 1")
        XCTAssertEqual(customFieldsAlert.alertActions[1].title, "Field 2")
        XCTAssertEqual(customFieldsAlert.alertActions[2].title, Localizations.cancel)

        try await customFieldsAlert.tapAction(title: "Field 2")

        XCTAssertEqual(textAutofillHelperDelegate.completeTextRequestText, "Custom Value 2")
    }

    /// `handleCipherForAutofill(cipherView:)` shows options with custom fields
    /// and user selects one custom field to autofill it when `viewPassword` is `false` so hidden fields are
    /// not avaialble.
    @MainActor
    func test_handleCipherForAutofill_optionsWithCustomFieldsNotViewPassword() async throws {
        let optionsHelper = MockTextAutofillOptionsHelper()
        optionsHelper.getTextAutofillOptionsResult = [
            ("Option 1", "Value 1"),
            ("Option 2", "Value 2"),
        ]
        textAutofillOptionsHelperFactory.createResult = optionsHelper
        vaultRepository.fetchCipherResult = .success(.fixture(
            fields: [
                .fixture(name: "Field 1", value: "Custom Value 1", type: .text),
                .fixture(name: "Field 2", value: "Custom Value 2", type: .hidden),
            ],
            id: "1",
            viewPassword: false
        ))

        let task = Task {
            try await subject.handleCipherForAutofill(
                cipherListView: CipherListView.fixture(
                    id: "1",
                    viewPassword: false
                )
            )
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return !textAutofillHelperDelegate.alertsShown.isEmpty
        }

        let alert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown.first)
        XCTAssertEqual(alert.title, Localizations.autofill)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions[0].title, "Option 1")
        XCTAssertEqual(alert.alertActions[1].title, "Option 2")
        XCTAssertEqual(alert.alertActions[2].title, Localizations.customFields)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.customFields)

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return textAutofillHelperDelegate.alertsShown.count == 2
        }

        let customFieldsAlert = try XCTUnwrap(textAutofillHelperDelegate.alertsShown[1])
        XCTAssertEqual(customFieldsAlert.title, Localizations.autofill)
        XCTAssertNil(customFieldsAlert.message)
        XCTAssertEqual(customFieldsAlert.alertActions[0].title, "Field 1")
        XCTAssertEqual(customFieldsAlert.alertActions[1].title, Localizations.cancel)

        try await customFieldsAlert.tapAction(title: "Field 1")

        XCTAssertEqual(textAutofillHelperDelegate.completeTextRequestText, "Custom Value 1")
    }
}

// MARK: - NoOpTextAutofillHelperTests

class NoOpTextAutofillHelperTests: BitwardenTestCase {
    func test_handleCipherForAutofill() async throws {
        let subject = NoOpTextAutofillHelper()
        await subject.handleCipherForAutofill(cipherListView: .fixture())
        throw XCTSkip("This TextAutofillHelper handleCipherForAutofill does nothing")
    }

    func test_setTextAutofillHelperDelegate() async throws {
        let subject = NoOpTextAutofillHelper()
        await subject.setTextAutofillHelperDelegate(MockTextAutofillHelperDelegate())
        throw XCTSkip("This TextAutofillHelper setTextAutofillHelperDelegate does nothing")
    }
}
