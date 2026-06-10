// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AddEditItemProcessorBankAccountTests

class AddEditItemProcessorBankAccountTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var appExtensionDelegate: MockAppExtensionDelegate!
    var billingRepository: MockBillingRepository!
    var billingService: MockBillingService!
    var cameraService: MockCameraService!
    var cardTextParser: MockCardTextParser!
    var client: MockHTTPClient!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockCipherItemOperationDelegate!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var rehydrationHelper: MockRehydrationHelper!
    var reviewPromptService: MockReviewPromptService!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var premiumUpgradeHelper: MockPremiumUpgradeHelper!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var totpService: MockTOTPService!
    var subject: AddEditItemProcessor!
    var vaultItemActionHelper: MockVaultItemActionHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() { // swiftlint:disable:this function_body_length
        super.setUp()

        authRepository = MockAuthRepository()
        appExtensionDelegate = MockAppExtensionDelegate()
        billingRepository = MockBillingRepository()
        billingService = MockBillingService()
        cameraService = MockCameraService()
        cardTextParser = MockCardTextParser()
        client = MockHTTPClient()
        configService = MockConfigService()
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        delegate = MockCipherItemOperationDelegate()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        rehydrationHelper = MockRehydrationHelper()
        reviewPromptService = MockReviewPromptService()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()
        totpService = MockTOTPService()
        premiumUpgradeHelper = MockPremiumUpgradeHelper()
        vaultItemActionHelper = MockVaultItemActionHelper()
        vaultRepository = MockVaultRepository()
        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                billingRepository: billingRepository,
                billingService: billingService,
                cameraService: cameraService,
                cardTextParser: cardTextParser,
                configService: configService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                rehydrationHelper: rehydrationHelper,
                reviewPromptService: reviewPromptService,
                settingsRepository: settingsRepository,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository,
            ),
            state: CipherItemState(
                customFields: [
                    CustomFieldState(
                        name: "fieldName1",
                        type: .hidden,
                        value: "old",
                    ),
                ],
                hasPremium: true,
            ),
            vaultItemActionHelper: vaultItemActionHelper,
        )
        subject.premiumUpgradeHelper = premiumUpgradeHelper
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        appExtensionDelegate = nil
        billingRepository = nil
        billingService = nil
        cameraService = nil
        cardTextParser = nil
        client = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        eventService = nil
        pasteboardService = nil
        rehydrationHelper = nil
        reviewPromptService = nil
        settingsRepository = nil
        stateService = nil
        subject = nil
        totpService = nil
        vaultItemActionHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.bankAccountFieldChanged(.bankNameChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_bankNameChanged() {
        subject.state.bankAccountItemState.bankName = "Old Bank"
        subject.receive(.bankAccountFieldChanged(.bankNameChanged("Bank of America")))
        XCTAssertEqual(subject.state.bankAccountItemState.bankName, "Bank of America")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.nameOnAccountChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_nameOnAccountChanged() {
        subject.state.bankAccountItemState.nameOnAccount = "Old Name"
        subject.receive(.bankAccountFieldChanged(.nameOnAccountChanged("Personal Checking")))
        XCTAssertEqual(subject.state.bankAccountItemState.nameOnAccount, "Personal Checking")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.accountTypeChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_accountTypeChanged() {
        subject.state.bankAccountItemState.accountType = .default
        subject.receive(.bankAccountFieldChanged(.accountTypeChanged(.custom(.checking))))
        XCTAssertEqual(subject.state.bankAccountItemState.accountType, .custom(.checking))
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.accountNumberChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_accountNumberChanged() {
        subject.state.bankAccountItemState.accountNumber = "111"
        subject.receive(.bankAccountFieldChanged(.accountNumberChanged("1234567890123456")))
        XCTAssertEqual(subject.state.bankAccountItemState.accountNumber, "1234567890123456")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.routingNumberChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_routingNumberChanged() {
        subject.state.bankAccountItemState.routingNumber = "111"
        subject.receive(.bankAccountFieldChanged(.routingNumberChanged("1234567890")))
        XCTAssertEqual(subject.state.bankAccountItemState.routingNumber, "1234567890")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.branchNumberChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_branchNumberChanged() {
        subject.state.bankAccountItemState.branchNumber = "1"
        subject.receive(.bankAccountFieldChanged(.branchNumberChanged("100")))
        XCTAssertEqual(subject.state.bankAccountItemState.branchNumber, "100")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.pinChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_pinChanged() {
        subject.state.bankAccountItemState.pin = "0000"
        subject.receive(.bankAccountFieldChanged(.pinChanged("1234")))
        XCTAssertEqual(subject.state.bankAccountItemState.pin, "1234")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.swiftCodeChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_swiftCodeChanged() {
        subject.state.bankAccountItemState.swiftCode = "000"
        subject.receive(.bankAccountFieldChanged(.swiftCodeChanged("123234")))
        XCTAssertEqual(subject.state.bankAccountItemState.swiftCode, "123234")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.ibanChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_ibanChanged() {
        subject.state.bankAccountItemState.iban = "000"
        subject.receive(.bankAccountFieldChanged(.ibanChanged("23423434543")))
        XCTAssertEqual(subject.state.bankAccountItemState.iban, "23423434543")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.bankContactPhoneChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_bankContactPhoneChanged() {
        subject.state.bankAccountItemState.bankContactPhone = "000"
        subject.receive(.bankAccountFieldChanged(.bankContactPhoneChanged("123-456-7890")))
        XCTAssertEqual(subject.state.bankAccountItemState.bankContactPhone, "123-456-7890")
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged)` updates
    /// the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_toggleAccountNumberVisibilityChanged() {
        subject.state.bankAccountItemState.isAccountNumberVisible = false
        subject.receive(.bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged(true)))
        XCTAssertTrue(subject.state.bankAccountItemState.isAccountNumberVisible)

        subject.receive(.bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged(false)))
        XCTAssertFalse(subject.state.bankAccountItemState.isAccountNumberVisible)
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.togglePinVisibilityChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_togglePinVisibilityChanged() {
        subject.state.bankAccountItemState.isPinVisible = false
        subject.receive(.bankAccountFieldChanged(.togglePinVisibilityChanged(true)))
        XCTAssertTrue(subject.state.bankAccountItemState.isPinVisible)

        subject.receive(.bankAccountFieldChanged(.togglePinVisibilityChanged(false)))
        XCTAssertFalse(subject.state.bankAccountItemState.isPinVisible)
    }

    /// `receive(_:)` with `.bankAccountFieldChanged(.toggleIbanVisibilityChanged)` updates the state correctly.
    @MainActor
    func test_receive_bankAccountFieldChanged_toggleIbanVisibilityChanged() {
        subject.state.bankAccountItemState.isIbanVisible = false
        subject.receive(.bankAccountFieldChanged(.toggleIbanVisibilityChanged(true)))
        XCTAssertTrue(subject.state.bankAccountItemState.isIbanVisible)

        subject.receive(.bankAccountFieldChanged(.toggleIbanVisibilityChanged(false)))
        XCTAssertFalse(subject.state.bankAccountItemState.isIbanVisible)
    }
}
