import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class GeneratorProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<GeneratorRoute, Void>!
    var errorReporter: MockErrorReporter!
    var generatorRepository: MockGeneratorRepository!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var reviewPromptService: MockReviewPromptService!
    var stateService: MockStateService!
    var subject: GeneratorProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        generatorRepository = MockGeneratorRepository()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        reviewPromptService = MockReviewPromptService()
        stateService = MockStateService()

        setUpSubject()
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        errorReporter = nil
        generatorRepository = nil
        pasteboardService = nil
        policyService = nil
        reviewPromptService = nil
        stateService = nil
        subject = nil
    }

    @MainActor
    func setUpSubject() {
        subject = GeneratorProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                generatorRepository: generatorRepository,
                pasteboardService: pasteboardService,
                policyService: policyService,
                reviewPromptService: reviewPromptService,
                stateService: stateService
            ),
            state: GeneratorState()
        )
    }

    // MARK: Tests

    /// `init` loads the password generation options and doesn't change the defaults if the options
    /// are empty.
    @MainActor
    func test_init_loadsPasswordOptions_empty() {
        waitFor { subject.didLoadGeneratorOptions }
        XCTAssertTrue(generatorRepository.getPasswordGenerationOptionsCalled)

        XCTAssertEqual(
            subject.state.passwordState,
            GeneratorState.PasswordState(
                avoidAmbiguous: false,
                containsLowercase: true,
                containsNumbers: true,
                containsSpecial: false,
                containsUppercase: true,
                length: 14,
                minimumNumber: 1,
                minimumSpecial: 1,
                capitalize: false,
                includeNumber: false,
                numberOfWords: 3,
                wordSeparator: "-"
            )
        )
        XCTAssertTrue(policyService.applyPasswordGenerationOptionsCalled)
        XCTAssertFalse(subject.state.isPolicyInEffect)
    }

    /// `init` loads the password generation options and updates the state
    /// based on the previously selected options.
    @MainActor
    func test_init_loadsPasswordOptions_withValues() {
        generatorRepository.getPasswordGenerationOptionsResult = .success(PasswordGenerationOptions(
            allowAmbiguousChar: false,
            capitalize: true,
            includeNumber: true,
            length: 30,
            lowercase: false,
            minLowercase: nil,
            minNumber: 3,
            minSpecial: 1,
            minUppercase: nil,
            number: false,
            numWords: 5,
            special: true,
            type: .passphrase,
            uppercase: false,
            wordSeparator: "*"
        ))

        setUpSubject()
        waitFor { subject.didLoadGeneratorOptions }

        XCTAssertEqual(subject.state.generatorType, .passphrase)
        XCTAssertEqual(
            subject.state.passwordState,
            GeneratorState.PasswordState(
                avoidAmbiguous: true,
                containsLowercase: false,
                containsNumbers: false,
                containsSpecial: true,
                containsUppercase: false,
                length: 30,
                minimumNumber: 3,
                minimumSpecial: 1,
                capitalize: true,
                includeNumber: true,
                numberOfWords: 5,
                wordSeparator: "*"
            )
        )
        XCTAssertTrue(policyService.applyPasswordGenerationOptionsCalled)
        XCTAssertFalse(subject.state.isPolicyInEffect)
    }

    /// `init` loads the password generation options, applies any policy options and updates the
    /// state based on the options.
    @MainActor
    func test_init_loadsPasswordOptions_withPolicy() {
        generatorRepository.getPasswordGenerationOptionsResult = .success(PasswordGenerationOptions(
            capitalize: false,
            length: 10,
            lowercase: false,
            minNumber: 5,
            minSpecial: 1,
            uppercase: false
        ))
        policyService.applyPasswordGenerationOptionsResult = true
        policyService.applyPasswordGenerationOptionsTransform = { options in
            options.capitalize = true
            options.length = 40
            options.lowercase = true
            options.number = true
            options.minNumber = 5
            options.minSpecial = 3
            options.special = true
            options.type = .passphrase
            options.uppercase = true
        }

        setUpSubject()
        waitFor { subject.didLoadGeneratorOptions }

        XCTAssertEqual(subject.state.generatorType, .passphrase)
        XCTAssertEqual(
            subject.state.passwordState,
            GeneratorState.PasswordState(
                avoidAmbiguous: false,
                containsLowercase: true,
                containsNumbers: true,
                containsSpecial: true,
                containsUppercase: true,
                length: 40,
                minimumNumber: 5,
                minimumSpecial: 3,
                capitalize: true,
                includeNumber: false,
                numberOfWords: 3,
                wordSeparator: "-"
            )
        )
        XCTAssertTrue(policyService.applyPasswordGenerationOptionsCalled)
        XCTAssertTrue(subject.state.isPolicyInEffect)
    }

    /// If an error occurs generating a password, an alert is shown.
    @MainActor
    func test_generatePassword_error() {
        subject.state.generatorType = .password

        struct PasswordGeneratorError: Error, Equatable {}
        generatorRepository.passwordResult = .failure(PasswordGeneratorError())

        subject.receive(.refreshGeneratedValue)

        waitFor { !coordinator.errorAlertsShown.isEmpty }
        XCTAssertEqual(coordinator.errorAlertsShown as? [PasswordGeneratorError], [PasswordGeneratorError()])
    }

    /// Generating a new password validates the password options before generating the value.
    @MainActor
    func test_generatePassword_validatesOptions() {
        subject.state.generatorType = .password

        subject.state.passwordState.containsLowercase = false
        subject.state.passwordState.containsNumbers = false
        subject.state.passwordState.containsSpecial = false
        subject.state.passwordState.containsUppercase = false

        subject.receive(.refreshGeneratedValue)
        waitFor { generatorRepository.passwordGeneratorRequest != nil }

        XCTAssertTrue(subject.state.passwordState.containsLowercase)
        XCTAssertEqual(generatorRepository.passwordGeneratorRequest?.lowercase, true)
    }

    /// Generating a new password applies any policies to the options before generating the value.
    @MainActor
    func test_generatePassword_appliesPolicies() throws {
        policyService.applyPasswordGenerationOptionsTransform = { options in
            options.length = 40
            options.lowercase = true
            options.uppercase = true
        }

        subject.state.generatorType = .password

        subject.state.passwordState.containsLowercase = false
        subject.state.passwordState.containsUppercase = false
        subject.state.passwordState.length = 10

        subject.receive(.refreshGeneratedValue)
        waitFor { generatorRepository.passwordGeneratorRequest != nil }

        XCTAssertTrue(subject.state.passwordState.containsLowercase)
        XCTAssertTrue(subject.state.passwordState.containsUppercase)
        XCTAssertEqual(subject.state.passwordState.length, 40)

        let passwordGeneratorRequest = try XCTUnwrap(generatorRepository.passwordGeneratorRequest)
        XCTAssertEqual(passwordGeneratorRequest.length, 40)
        XCTAssertEqual(passwordGeneratorRequest.lowercase, true)
        XCTAssertEqual(passwordGeneratorRequest.uppercase, true)

        XCTAssertTrue(policyService.applyPasswordGenerationOptionsCalled)
    }

    /// Generating a new password applies any policies to the options before generating the value,
    /// and overrides the generator type.
    @MainActor
    func test_generatePassword_appliesPolicies_generatorTypeChange() throws {
        waitFor(subject.didLoadGeneratorOptions)

        policyService.applyPasswordGenerationOptionsTransform = { options in
            options.type = .password
        }

        subject.state.generatorType = .passphrase

        subject.receive(.refreshGeneratedValue)
        waitFor { generatorRepository.passwordGeneratorRequest != nil }

        XCTAssertEqual(subject.state.generatorType, .password)
    }

    /// If an error occurs generating an username, an alert is shown.
    @MainActor
    func test_generateUsername_error() {
        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .plusAddressedEmail

        struct UsernameGeneratorError: Error, Equatable {}
        generatorRepository.usernameResult = .failure(UsernameGeneratorError())

        subject.receive(.refreshGeneratedValue)

        waitFor { !coordinator.errorAlertsShown.isEmpty }
        XCTAssertEqual(coordinator.errorAlertsShown as? [UsernameGeneratorError], [UsernameGeneratorError()])
    }

    /// If an error occurs loading the generator options, an alert is shown and a new value isn't generated.
    @MainActor
    func test_generateValue_loadGeneratorOptionsError() async {
        generatorRepository.getPasswordGenerationOptionsResult = .failure(StateServiceError.noActiveAccount)
        setUpSubject()

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(
            errorReporter.errors as? [StateServiceError],
            [
                StateServiceError.noActiveAccount,
                StateServiceError.noActiveAccount,
            ]
        )
        XCTAssertNil(generatorRepository.passwordGeneratorRequest)
        XCTAssertEqual(subject.state.generatedValue, "")
    }

    /// `init` loads the username generation options and doesn't change the defaults if the options
    /// are empty.
    @MainActor
    func test_init_loadsUsernameOptions_empty() {
        waitFor { generatorRepository.getUsernameGenerationOptionsCalled }
        XCTAssertTrue(generatorRepository.getUsernameGenerationOptionsCalled)

        XCTAssertEqual(
            subject.state.usernameState,
            GeneratorState.UsernameState(
                usernameGeneratorType: .plusAddressedEmail,
                catchAllEmailType: .random,
                domain: "",
                addyIOAPIAccessToken: "",
                addyIODomainName: "",
                duckDuckGoAPIKey: "",
                fastmailAPIKey: "",
                firefoxRelayAPIAccessToken: "",
                forwardedEmailService: .addyIO,
                forwardEmailAPIToken: "",
                forwardEmailDomainName: "",
                simpleLoginAPIKey: "",
                email: "",
                plusAddressedEmailType: .random,
                capitalize: false,
                includeNumber: false
            )
        )
    }

    /// `perform(_:)` with `.appeared` loads the username generation options and updates the state
    /// based on the previously selected options.
    @MainActor
    func test_init_loadsUsernameOptions_withValues() {
        generatorRepository.getUsernameGenerationOptionsResult = .success(UsernameGenerationOptions(
            anonAddyApiAccessToken: "ADDYIO_API_TOKEN",
            anonAddyDomainName: "bitwarden.com",
            capitalizeRandomWordUsername: true,
            catchAllEmailDomain: "bitwarden.com",
            catchAllEmailType: .random,
            duckDuckGoApiKey: "DUCKDUCKGO_API_KEY",
            fastMailApiKey: "FASTMAIL_API_KEY",
            firefoxRelayApiAccessToken: "FIREFOX_API_TOKEN",
            forwardEmailApiToken: "FORWARDEMAIL_API_TOKEN",
            forwardEmailDomainName: "bitwarden.com",
            includeNumberRandomWordUsername: true,
            plusAddressedEmail: "user@bitwarden.com",
            plusAddressedEmailType: .random,
            serviceType: .fastmail,
            simpleLoginApiKey: "SIMPLELOGIN_API_KEY",
            type: .randomWord
        ))

        setUpSubject()
        waitFor { subject.state.usernameState.usernameGeneratorType == .randomWord }

        XCTAssertEqual(
            subject.state.usernameState,
            GeneratorState.UsernameState(
                usernameGeneratorType: .randomWord,
                catchAllEmailType: .random,
                domain: "bitwarden.com",
                addyIOAPIAccessToken: "ADDYIO_API_TOKEN",
                addyIODomainName: "bitwarden.com",
                duckDuckGoAPIKey: "DUCKDUCKGO_API_KEY",
                fastmailAPIKey: "FASTMAIL_API_KEY",
                firefoxRelayAPIAccessToken: "FIREFOX_API_TOKEN",
                forwardedEmailService: .fastmail,
                forwardEmailAPIToken: "FORWARDEMAIL_API_TOKEN",
                forwardEmailDomainName: "bitwarden.com",
                simpleLoginAPIKey: "SIMPLELOGIN_API_KEY",
                email: "user@bitwarden.com",
                plusAddressedEmailType: .random,
                capitalize: true,
                includeNumber: true
            )
        )
    }

    /// `perform(_:)` with `.appeared` generates a new generated value.
    @MainActor
    func test_perform_appear_generatesValue() {
        subject.state.generatorType = .password

        waitFor(subject.didLoadGeneratorOptions)

        Task {
            await subject.perform(.appeared)
        }
        waitFor(generatorRepository.passwordGeneratorRequest != nil)

        XCTAssertNotNil(generatorRepository.passwordGeneratorRequest)
    }

    /// `perform(_:)` with `.appeared` generates a new generated value after the options have loaded.
    @MainActor
    func test_perform_appear_generatesValueAfterLoadingOptions() {
        generatorRepository.getPasswordGenerationOptionsResult = .success(
            PasswordGenerationOptions(length: 50)
        )
        setUpSubject()

        Task {
            await subject.perform(.appeared)
        }
        waitFor(generatorRepository.passwordGeneratorRequest != nil)

        XCTAssertEqual(generatorRepository.passwordGeneratorRequest?.length, 50)
    }

    /// `perform(_:)` with `.appeared` calls `reloadGeneratorOptions` and
    ///  loads the generator options.
    @MainActor
    func test_perform_appeared_reloadGeneratorOptions() {
        waitFor(subject.didLoadGeneratorOptions)

        XCTAssertTrue(generatorRepository.getPasswordGenerationOptionsCalled)
        generatorRepository.getPasswordGenerationOptionsCalled = false

        Task {
            await subject.perform(.appeared)
        }
        waitFor(generatorRepository.passwordGeneratorRequest != nil)
        XCTAssertTrue(generatorRepository.getPasswordGenerationOptionsCalled)
    }

    /// `perform(_:)` with `.appeared` logs an error when `loadGeneratorOptions` throws an error.
    @MainActor
    func test_perform_appear_reloadGeneratorOptions_logsError() {
        waitFor(subject.didLoadGeneratorOptions)

        XCTAssertTrue(generatorRepository.getPasswordGenerationOptionsCalled)
        generatorRepository.getPasswordGenerationOptionsCalled = false
        generatorRepository.getPasswordGenerationOptionsResult = .failure(
            BitwardenTestError.example
        )
        Task {
            await subject.perform(.appeared)
        }
        waitFor { !errorReporter.errors.isEmpty }
        XCTAssertEqual(
            errorReporter.errors[0] as? BitwardenTestError,
            BitwardenTestError.example
        )
    }

    /// `perform(:)` with `.appeared` should set the `isLearnGeneratorActionCardEligible` to `true`
    /// if the `learnGeneratorActionCardStatus` is `incomplete`.
    @MainActor
    func test_perform_checkLearnNewLoginActionCardEligibility() async {
        stateService.learnGeneratorActionCardStatus = .incomplete
        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.isLearnGeneratorActionCardEligible)
    }

    /// `perform(:)` with `.appeared` should not set the `isLearnNewLoginActionCardEligible` to `true`
    /// if the `learnGeneratorActionCardStatus` is `complete`.
    @MainActor
    func test_perform_checkLearnNewLoginActionCardEligibility_false_complete() async {
        stateService.learnGeneratorActionCardStatus = .complete
        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.isLearnGeneratorActionCardEligible)
    }

    /// `receive(_:)` with `.copyGeneratedValØue` copies the generated password to the system
    /// pasteboard and shows a toast.
    @MainActor
    func test_receive_copiedGeneratedValue_password() {
        subject.state.generatorType = .password

        subject.state.generatedValue = "PASSWORD"
        subject.receive(.copyGeneratedValue)
        waitFor { !reviewPromptService.userActions.isEmpty }

        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.password)))
        XCTAssertEqual(reviewPromptService.userActions, [.copiedOrInsertedGeneratedValue])
    }

    /// `receive(_:)` with `.copyGeneratedValue` copies the generated passphrase to the system
    /// pasteboard and shows a toast.
    @MainActor
    func test_receive_copiedGeneratedValue_passphrase() {
        subject.state.generatorType = .passphrase

        subject.state.generatedValue = "PASSPHRASE"
        subject.receive(.copyGeneratedValue)
        waitFor { !reviewPromptService.userActions.isEmpty }

        XCTAssertEqual(pasteboardService.copiedString, "PASSPHRASE")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.passphrase)))
        XCTAssertEqual(reviewPromptService.userActions, [.copiedOrInsertedGeneratedValue])
    }

    /// `receive(_:)` with `.copyGeneratedValue` copies the generated username to the system
    /// pasteboard and shows a toast.
    @MainActor
    func test_receive_copiedGeneratedValue_username() {
        subject.state.generatorType = .username

        subject.state.generatedValue = "USERNAME"
        subject.receive(.copyGeneratedValue)
        waitFor { !reviewPromptService.userActions.isEmpty }

        XCTAssertEqual(pasteboardService.copiedString, "USERNAME")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.valueHasBeenCopied(Localizations.username)))
        XCTAssertEqual(reviewPromptService.userActions, [.copiedOrInsertedGeneratedValue])
    }

    /// `receive(_:)` with `.dismissPressed` navigates to the `.cancel` route.
    @MainActor
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .cancel)
    }

    /// `perform(_:)` with `.dismissNewLoginActionCard` will set `.isLearnGeneratorActionCardEligible` to
    /// false  and updates `.learnGeneratorActionCardStatus` via  stateService.
    @MainActor
    func test_perform_dismissLearnGeneratorActionCard() async {
        subject.state.isLearnGeneratorActionCardEligible = true
        await subject.perform(.dismissLearnGeneratorActionCard)
        XCTAssertFalse(subject.state.isLearnGeneratorActionCardEligible)
        XCTAssertEqual(stateService.learnGeneratorActionCardStatus, .complete)
    }

    /// `perform(_:)` with `.showLearnGeneratorGuidedTour` sets `isLearnGeneratorActionCardEligible`
    /// to `false`.
    @MainActor
    func test_perform_showLearnNewLoginGuidedTour() async {
        subject.state.guidedTourViewState.showGuidedTour = false
        subject.state.isLearnGeneratorActionCardEligible = true
        subject.state.generatorType = .username
        await subject.perform(.showLearnGeneratorGuidedTour)
        XCTAssertFalse(subject.state.isLearnGeneratorActionCardEligible)
        XCTAssertEqual(stateService.learnGeneratorActionCardStatus, .complete)
        XCTAssertEqual(subject.state.generatorType, .password)
        XCTAssertTrue(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.emailTypeChanged` updates the state's catch all email type.
    @MainActor
    func test_receive_emailTypeChanged_catchAll() {
        subject.state.usernameState.usernameGeneratorType = .catchAllEmail

        subject.receive(.emailTypeChanged(.website))
        XCTAssertEqual(subject.state.usernameState.catchAllEmailType, .website)

        subject.receive(.emailTypeChanged(.random))
        XCTAssertEqual(subject.state.usernameState.catchAllEmailType, .random)
    }

    /// `receive(_:)` with `.emailTypeChanged` updates the state's plus addressed email type.
    @MainActor
    func test_receive_emailTypeChanged_plusAddressed() {
        subject.state.usernameState.usernameGeneratorType = .plusAddressedEmail

        subject.receive(.emailTypeChanged(.website))
        XCTAssertEqual(subject.state.usernameState.plusAddressedEmailType, .website)

        subject.receive(.emailTypeChanged(.random))
        XCTAssertEqual(subject.state.usernameState.plusAddressedEmailType, .random)
    }

    /// `receive(_:)` with `.generatorTypeChanged` updates the state's generator type value.
    @MainActor
    func test_receive_generatorTypeChanged() {
        subject.receive(.generatorTypeChanged(.password))
        XCTAssertEqual(subject.state.generatorType, .password)

        subject.receive(.generatorTypeChanged(.username))
        XCTAssertEqual(subject.state.generatorType, .username)
    }

    /// `receive(_:)` with `.guidedTourViewAction(.backTapped)` updates the guided tour state to the previous step.
    @MainActor
    func test_receive_guidedTourViewAction_backTapped() {
        subject.state.guidedTourViewState.currentIndex = 1

        subject.receive(.guidedTourViewAction(.backTapped))
        XCTAssertEqual(subject.state.guidedTourViewState.currentIndex, 0)
    }

    /// `receive(_:)` with `.guidedTourViewAction(.nextTapped)` updates the guided tour state to the next step.
    @MainActor
    func test_receive_guidedTourViewAction_nextTapped() {
        subject.state.guidedTourViewState.currentIndex = 0

        subject.receive(.guidedTourViewAction(.nextTapped))
        XCTAssertEqual(subject.state.guidedTourViewState.currentIndex, 1)
    }

    /// `receive(_:)` with `.guidedTourViewAction(.doneTapped)` completes the guided tour.
    @MainActor
    func test_receive_doneTapped() {
        subject.receive(.guidedTourViewAction(.doneTapped))
        XCTAssertFalse(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.guidedTourViewAction(.dismissTapped)` dismisses the guided tour.
    @MainActor
    func test_receive_guidedTourViewAction_dismissTapped() {
        subject.receive(.guidedTourViewAction(.dismissTapped))
        XCTAssertFalse(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.guidedTourViewAction(.didRenderViewToSpotlight)` updates the spotlight region.
    @MainActor
    func test_receive_guidedTourViewAction_didRenderViewToSpotlight() {
        let frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        subject.state.guidedTourViewState.currentIndex = 0

        subject.receive(.guidedTourViewAction(.didRenderViewToSpotlight(frame: frame, step: .step1)))
        XCTAssertEqual(subject.state.guidedTourViewState.currentStepState.spotlightRegion, frame)
    }

    /// `receive(_:)` with `.guidedTourViewAction(.toggleGuidedTourVisibilityChanged)`
    /// updates the visibility of the guided tour.
    @MainActor
    func test_receive_guidedTourViewAction_toggleGuidedTourVisibilityChanged() {
        subject.state.guidedTourViewState.showGuidedTour = false

        subject.receive(.guidedTourViewAction(.toggleGuidedTourVisibilityChanged(true)))
        XCTAssertTrue(subject.state.guidedTourViewState.showGuidedTour)

        subject.receive(.guidedTourViewAction(.toggleGuidedTourVisibilityChanged(false)))
        XCTAssertFalse(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new passphrase.
    @MainActor
    func test_receive_refreshGeneratedValue_passphrase() throws {
        waitFor(subject.didLoadGeneratorOptions)

        subject.state.generatorType = .passphrase

        subject.receive(.refreshGeneratedValue)

        waitFor { !generatorRepository.passwordHistorySubject.value.isEmpty }

        XCTAssertEqual(
            generatorRepository.passphraseGeneratorRequest,
            PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: false,
                includeNumber: false
            )
        )

        XCTAssertEqual(subject.state.generatedValue, "PASSPHRASE")
        XCTAssertEqual(generatorRepository.passwordHistorySubject.value.count, 1)
        let passwordHistory = try XCTUnwrap(generatorRepository.passwordHistorySubject.value.first)
        XCTAssertEqual(passwordHistory.password, "PASSPHRASE")
        XCTAssertEqual(passwordHistory.lastUsedDate.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.1)
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new password.
    @MainActor
    func test_receive_refreshGeneratedValue_password() throws {
        subject.state.generatorType = .password

        subject.receive(.refreshGeneratedValue)

        waitFor { !generatorRepository.passwordHistorySubject.value.isEmpty }

        XCTAssertEqual(
            generatorRepository.passwordGeneratorRequest,
            PasswordGeneratorRequest(
                lowercase: true,
                uppercase: true,
                numbers: true,
                special: false,
                length: 14,
                avoidAmbiguous: false,
                minLowercase: 1,
                minUppercase: 1,
                minNumber: 1,
                minSpecial: nil
            )
        )

        XCTAssertEqual(subject.state.generatedValue, "PASSWORD")
        XCTAssertEqual(generatorRepository.passwordHistorySubject.value.count, 1)
        let passwordHistory = try XCTUnwrap(generatorRepository.passwordHistorySubject.value.first)
        XCTAssertEqual(passwordHistory.password, "PASSWORD")
        XCTAssertEqual(passwordHistory.lastUsedDate.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.1)
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new username.
    @MainActor
    func test_receive_refreshGeneratedValue_username() throws {
        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        subject.state.usernameState.email = "user@bitwarden.com"

        subject.receive(.refreshGeneratedValue)

        waitFor { subject.state.generatedValue == "USERNAME" }

        XCTAssertEqual(
            generatorRepository.usernameGeneratorRequest,
            UsernameGeneratorRequest.subaddress(type: .random, email: "user@bitwarden.com")
        )

        XCTAssertEqual(subject.state.generatedValue, "USERNAME")
        XCTAssertFalse(generatorRepository.addPasswordHistoryCalled)
    }

    /// `receive(_:)` with `.selectButtonPressed` navigates to the `.complete` route.
    @MainActor
    func test_receive_selectButtonPressed() {
        subject.state.generatorType = .password
        subject.state.generatedValue = "password"
        subject.receive(.selectButtonPressed)
        XCTAssertEqual(coordinator.routes.last, .complete(type: .password, value: "password"))
        waitFor(!reviewPromptService.userActions.isEmpty)
        XCTAssertEqual(reviewPromptService.userActions, [.copiedOrInsertedGeneratedValue])
    }

    /// `receive(_:)` with `.showPasswordHistory` asks the coordinator to show the password history.
    @MainActor
    func test_receive_showPasswordHistory() {
        subject.receive(.showPasswordHistory)

        XCTAssertEqual(coordinator.routes.last, .generatorHistory)
    }

    /// `receive(_:)` with `.sliderEditingChanged` saves the previously generated value when the
    /// slider ends editing.
    @MainActor
    func test_receive_sliderEditingChanged() {
        let field = sliderField(
            keyPath: \.passwordState.lengthDouble,
            sliderAccessibilityId: "PasswordLengthSlider",
            sliderValueAccessibilityId: "PasswordLengthLabel"
        )

        subject.receive(.sliderEditingChanged(field: field, isEditing: true))

        generatorRepository.passwordResult = .success("PASSSSWORD")
        subject.receive(.sliderValueChanged(field: field, value: 10))
        waitFor(subject.state.generatedValue.count == 10)

        generatorRepository.passwordResult = .success("PASSSSSSSSSWORD")
        subject.receive(.sliderValueChanged(field: field, value: 15))
        waitFor(subject.state.generatedValue.count == 15)

        generatorRepository.passwordResult = .success("PASSSSSSSSSSSSSSWORD")
        subject.receive(.sliderValueChanged(field: field, value: 20))
        waitFor(subject.state.generatedValue.count == 20)

        generatorRepository.passwordGeneratorRequest = nil
        subject.receive(.sliderEditingChanged(field: field, isEditing: false))
        waitFor(generatorRepository.passwordHistorySubject.value.last?.password.count == 20)

        // Only the final password should be saved when the slider ends editing.
        XCTAssertEqual(
            generatorRepository.passwordHistorySubject.value.map(\.password),
            ["PASSSSSSSSSSSSSSWORD"]
        )
    }

    /// `receive(_:)` with `.sliderValueChanged` updates the state's value for the slider field.
    @MainActor
    func test_receive_sliderValueChanged() {
        let field = sliderField(
            keyPath: \.passwordState.lengthDouble,
            sliderAccessibilityId: "PasswordLengthSlider",
            sliderValueAccessibilityId: "PasswordLengthLabel"
        )

        subject.receive(.sliderValueChanged(field: field, value: 10))
        XCTAssertEqual(subject.state.passwordState.length, 10)

        subject.receive(.sliderValueChanged(field: field, value: 30))
        XCTAssertEqual(subject.state.passwordState.length, 30)
    }

    /// `receive(_:)` with `.sliderValueChanged` doesn't generate a new value if the slider value is
    /// below the policy minimum.
    @MainActor
    func test_receive_sliderValueChanged_withPolicy() {
        subject.state.policyOptions = PasswordGenerationOptions(length: 20)

        let field = sliderField(
            keyPath: \.passwordState.lengthDouble,
            sliderAccessibilityId: "PasswordLengthSlider",
            sliderValueAccessibilityId: "PasswordLengthLabel"
        )

        subject.receive(.sliderValueChanged(field: field, value: 10))
        subject.receive(.sliderEditingChanged(field: field, isEditing: false))
        XCTAssertNil(generatorRepository.passwordGeneratorRequest)

        subject.receive(.sliderValueChanged(field: field, value: 19))
        subject.receive(.sliderEditingChanged(field: field, isEditing: false))
        XCTAssertNil(generatorRepository.passwordGeneratorRequest)

        subject.receive(.sliderValueChanged(field: field, value: 20))
        subject.receive(.sliderEditingChanged(field: field, isEditing: false))
        waitFor(generatorRepository.passwordGeneratorRequest != nil)
        XCTAssertEqual(generatorRepository.passwordGeneratorRequest?.length, 20)
    }

    /// `receive(_:)` with `.stepperValueChanged` updates the state's value for the stepper field.
    @MainActor
    func test_receive_stepperValueChanged() {
        let field = stepperField(
            accessibilityId: "",
            keyPath: \.passwordState.minimumNumber
        )

        subject.receive(.stepperValueChanged(field: field, value: 3))
        XCTAssertEqual(subject.state.passwordState.minimumNumber, 3)

        subject.receive(.stepperValueChanged(field: field, value: 5))
        XCTAssertEqual(subject.state.passwordState.minimumNumber, 5)
    }

    /// `receive(_:)` with `.textFieldFocusChanged` updates the processor's focused key path value
    /// which is used to determine if a new value should be generated as the text field value changes.
    @MainActor
    func test_receive_textFieldFocusChanged() {
        let field = FormTextField<GeneratorState>(
            keyPath: \.usernameState.email,
            title: Localizations.email,
            value: "user@"
        )

        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .plusAddressedEmail

        subject.receive(.textFieldFocusChanged(keyPath: \.usernameState.email))
        subject.receive(.textValueChanged(field: field, value: "user@bitwarden.com"))
        XCTAssertNil(generatorRepository.usernamePlusAddressEmail)

        subject.receive(.textFieldFocusChanged(keyPath: nil))
        waitFor { subject.state.generatedValue == "USERNAME" }
        XCTAssertEqual(
            generatorRepository.usernameGeneratorRequest,
            UsernameGeneratorRequest.subaddress(type: .random, email: "user@bitwarden.com")
        )
        XCTAssertEqual(subject.state.generatedValue, "USERNAME")
    }

    /// `receive(_:)` with `.textFieldIsPasswordVisibleChanged` updates the states value for whether
    /// the password is visible for the field.
    @MainActor
    func test_receive_textFieldIsPasswordVisibleChanged() {
        let field = FormTextField<GeneratorState>(
            isPasswordVisible: false,
            isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
            keyPath: \.usernameState.addyIOAPIAccessToken,
            title: Localizations.apiAccessToken,
            value: ""
        )

        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .forwardedEmail

        subject.receive(.textFieldIsPasswordVisibleChanged(field: field, value: true))
        XCTAssertTrue(subject.state.usernameState.isAPIKeyVisible)

        subject.receive(.textFieldIsPasswordVisibleChanged(field: field, value: false))
        XCTAssertFalse(subject.state.usernameState.isAPIKeyVisible)
    }

    /// `receive(_:)` with `.textValueChanged` updates the state's value for the text field.
    @MainActor
    func test_receive_textValueChanged() {
        let field = textField(keyPath: \.passwordState.wordSeparator)

        subject.receive(.textValueChanged(field: field, value: "*"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "*")

        subject.receive(.textValueChanged(field: field, value: "!"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "!")
    }

    /// `receive(_:)` with `.textValueChanged` for the word separator limits the value to one character.
    @MainActor
    func test_receive_textValueChanged_wordSeparatorLimitedToOneCharacter() {
        let field = FormTextField<GeneratorState>(
            keyPath: \.passwordState.wordSeparator,
            title: Localizations.wordSeparator,
            value: "-"
        )

        subject.receive(.textValueChanged(field: field, value: "-*"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "-")

        subject.receive(.textValueChanged(field: field, value: "abc"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "a")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.toggleValueChanged` updates the state's value for the toggle field.
    @MainActor
    func test_receive_toggleValueChanged() {
        let field = toggleField(accessibilityId: "LowercaseAtoZToggle", keyPath: \.passwordState.containsLowercase)

        subject.receive(.toggleValueChanged(field: field, isOn: true))
        XCTAssertTrue(subject.state.passwordState.containsLowercase)

        subject.receive(.toggleValueChanged(field: field, isOn: false))
        XCTAssertFalse(subject.state.passwordState.containsLowercase)
    }

    /// `receive(_:)` with `.usernameForwardedEmailServiceChanged` updates the state's username
    /// forwarded email service value.
    @MainActor
    func test_receive_usernameForwardedEmailServiceChanged() {
        subject.receive(.usernameForwardedEmailServiceChanged(.duckDuckGo))
        XCTAssertEqual(subject.state.usernameState.forwardedEmailService, .duckDuckGo)

        subject.receive(.usernameForwardedEmailServiceChanged(.simpleLogin))
        XCTAssertEqual(subject.state.usernameState.forwardedEmailService, .simpleLogin)
    }

    /// `receive(_:)` with `.usernameGeneratorTypeChanged` updates the state's username generator type value.
    @MainActor
    func test_receive_usernameGeneratorTypeChanged() {
        subject.receive(.usernameGeneratorTypeChanged(.plusAddressedEmail))
        XCTAssertEqual(subject.state.usernameState.usernameGeneratorType, .plusAddressedEmail)

        subject.receive(.usernameGeneratorTypeChanged(.catchAllEmail))
        XCTAssertEqual(subject.state.usernameState.usernameGeneratorType, .catchAllEmail)
    }

    /// The user's password options are saved when any of the password options are changed.
    @MainActor
    func test_saveGeneratorOptions_password() {
        // Wait for the initial loading of the generation options to complete before making changes.
        waitFor { subject.didLoadGeneratorOptions }

        subject.receive(.generatorTypeChanged(.passphrase))
        waitFor { generatorRepository.passwordGenerationOptions.type == .passphrase }
        XCTAssertEqual(
            generatorRepository.passwordGenerationOptions,
            PasswordGenerationOptions(
                allowAmbiguousChar: true,
                capitalize: false,
                includeNumber: false,
                length: 14,
                lowercase: true,
                minLowercase: nil,
                minNumber: 1,
                minSpecial: 1,
                minUppercase: nil,
                number: true,
                numWords: 3,
                special: false,
                type: .passphrase,
                uppercase: true,
                wordSeparator: "-"
            )
        )

        let sliderField = sliderField(
            keyPath: \.passwordState.lengthDouble,
            sliderAccessibilityId: "PasswordLengthSlider",
            sliderValueAccessibilityId: "PasswordLengthLabel"
        )
        subject.receive(.sliderValueChanged(field: sliderField, value: 30))
        waitFor { generatorRepository.passwordGenerationOptions.length == 30 }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.length, 30)

        subject.receive(
            .stepperValueChanged(
                field: stepperField(accessibilityId: "MinNumberValueLabel", keyPath: \.passwordState.minimumNumber),
                value: 4
            )
        )
        waitFor { generatorRepository.passwordGenerationOptions.minNumber == 4 }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.minNumber, 4)

        subject.receive(.textValueChanged(field: textField(keyPath: \.passwordState.wordSeparator), value: "$"))
        waitFor { generatorRepository.passwordGenerationOptions.wordSeparator == "$" }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.wordSeparator, "$")

        subject.receive(.toggleValueChanged(
            field: toggleField(accessibilityId: "LowercaseAtoZToggle", keyPath: \.passwordState.containsLowercase),
            isOn: false
        ))
        waitFor { generatorRepository.passwordGenerationOptions.lowercase == false }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.lowercase, false)
    }

    /// Saving the password generation options logs an error if one occurs.
    @MainActor
    func test_saveGeneratorOptions_password_error() {
        generatorRepository.setPasswordGenerationOptionsResult = .failure(StateServiceError.noActiveAccount)

        subject.receive(.generatorTypeChanged(.passphrase))

        waitFor { !errorReporter.errors.isEmpty }
        XCTAssertEqual(
            errorReporter.errors[0] as NSError,
            BitwardenError.generatorOptionsError(error: StateServiceError.noActiveAccount)
        )
    }

    /// The user's username options are saved when any of the username options are changed.
    @MainActor
    func test_saveGeneratorOptions_username() {
        // Wait for the initial loading of the generation options to complete before making changes.
        waitFor { generatorRepository.getUsernameGenerationOptionsCalled }

        subject.state.generatorType = .username

        subject.receive(.usernameGeneratorTypeChanged(.catchAllEmail))
        waitFor { generatorRepository.usernameGenerationOptions.type == .catchAllEmail }
        XCTAssertEqual(
            generatorRepository.usernameGenerationOptions,
            UsernameGenerationOptions(
                capitalizeRandomWordUsername: false,
                catchAllEmailType: .random,
                includeNumberRandomWordUsername: false,
                plusAddressedEmailType: .random,
                serviceType: .addyIO,
                type: .catchAllEmail
            )
        )

        subject.receive(.usernameForwardedEmailServiceChanged(.duckDuckGo))
        waitFor { generatorRepository.usernameGenerationOptions.serviceType == .duckDuckGo }
        XCTAssertEqual(generatorRepository.usernameGenerationOptions.serviceType, .duckDuckGo)

        subject.receive(.textValueChanged(
            field: textField(keyPath: \.usernameState.duckDuckGoAPIKey),
            value: "API_KEY"
        ))
        waitFor { generatorRepository.usernameGenerationOptions.duckDuckGoApiKey == "API_KEY" }
        XCTAssertEqual(generatorRepository.usernameGenerationOptions.duckDuckGoApiKey, "API_KEY")

        subject.receive(
            .toggleValueChanged(
                field: toggleField(
                    accessibilityId: "CapitalizeRandomWordUsernameToggle",
                    keyPath: \.usernameState.capitalize
                ),
                isOn: true
            )
        )
        waitFor { generatorRepository.usernameGenerationOptions.capitalizeRandomWordUsername == true }
        XCTAssertEqual(generatorRepository.usernameGenerationOptions.capitalizeRandomWordUsername, true)
    }

    /// Saving the username generation options logs an error if one occurs.
    @MainActor
    func test_saveGeneratorOptions_username_error() {
        generatorRepository.setUsernameGenerationOptionsResult = .failure(StateServiceError.noActiveAccount)

        subject.state.generatorType = .username
        subject.receive(.usernameGeneratorTypeChanged(.catchAllEmail))

        waitFor { !errorReporter.errors.isEmpty }
        XCTAssertEqual(
            errorReporter.errors[0] as NSError,
            BitwardenError.generatorOptionsError(error: StateServiceError.noActiveAccount)
        )
    }

    /// A new value should only be generated when focus leaves a text field, and not when a text
    /// field becomes focused.
    @MainActor
    func test_shouldGenerateNewValue_textFieldFocusChanged() {
        XCTAssertFalse(
            GeneratorAction.textFieldFocusChanged(keyPath: \.passwordState.wordSeparator)
                .shouldGenerateNewValue
        )

        XCTAssertTrue(GeneratorAction.textFieldFocusChanged(keyPath: nil).shouldGenerateNewValue)
    }

    // MARK: Private

    /// Creates a `SliderField` with the specified key path.
    private func sliderField(
        keyPath: WritableKeyPath<GeneratorState, Double>,
        sliderAccessibilityId: String,
        sliderValueAccessibilityId: String
    ) -> SliderField<GeneratorState> {
        SliderField<GeneratorState>(
            keyPath: keyPath,
            range: 5 ... 128,
            sliderAccessibilityId: sliderAccessibilityId,
            sliderValueAccessibilityId: sliderValueAccessibilityId,
            step: 1,
            title: Localizations.length,
            value: 14
        )
    }

    /// Creates a `StepperField` with the specified key path.
    private func stepperField(
        accessibilityId: String,
        keyPath: WritableKeyPath<GeneratorState, Int>
    ) -> StepperField<GeneratorState> {
        StepperField<GeneratorState>(
            accessibilityId: accessibilityId,
            keyPath: keyPath,
            range: 0 ... 5,
            title: Localizations.minNumbers,
            value: 1
        )
    }

    /// Creates a `FormTextField` with the specified key path.
    private func textField(keyPath: WritableKeyPath<GeneratorState, String>) -> FormTextField<GeneratorState> {
        FormTextField<GeneratorState>(
            keyPath: keyPath,
            title: Localizations.wordSeparator,
            value: "-"
        )
    }

    /// Creates a `ToggleField` with the specified key path.
    private func toggleField(
        accessibilityId: String,
        keyPath: WritableKeyPath<GeneratorState, Bool>
    ) -> ToggleField<GeneratorState> {
        ToggleField<GeneratorState>(
            accessibilityId: accessibilityId,
            accessibilityLabel: Localizations.lowercaseAtoZ,
            isDisabled: false,
            isOn: true,
            keyPath: keyPath,
            title: "a-z"
        )
    }
}
