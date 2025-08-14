import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AddItemProcessorTests

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class AddEditItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var appExtensionDelegate: MockAppExtensionDelegate!
    var cameraService: MockCameraService!
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
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var totpService: MockTOTPService!
    var subject: AddEditItemProcessor!
    var vaultRepository: MockVaultRepository!

    let step1Spotlight = CGRect(x: 5, y: 5, width: 25, height: 25)

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        appExtensionDelegate = MockAppExtensionDelegate()
        cameraService = MockCameraService()
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
        vaultRepository = MockVaultRepository()
        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
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
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                customFields: [
                    CustomFieldState(
                        name: "fieldName1",
                        type: .hidden,
                        value: "old"
                    ),
                ],
                hasPremium: true
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        appExtensionDelegate = nil
        cameraService = nil
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
        vaultRepository = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.customField(.booleanFieldChanged)` changes
    /// the boolean value of the custom field.
    @MainActor
    func test_customField_booleanFieldChanged() {
        subject.state.customFieldsState.customFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .boolean,
                value: "true"
            ),
        ]
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .boolean)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.booleanValue, true)
        subject.receive(.customField(.booleanFieldChanged(false, 0)))
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.booleanValue, false)
    }

    /// `receive(_:)` with `.customField(.customFieldAdded)` adds a new custom field view.
    @MainActor
    func test_customField_customFieldAdded() {
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        subject.receive(.customField(.customFieldAdded(.text, "fieldName2")))
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields[1].name, "fieldName2")
        XCTAssertEqual(subject.state.customFieldsState.customFields[1].type, .text)
        XCTAssertNil(subject.state.customFieldsState.customFields[1].value)
    }

    /// `receive(_:)` with `.customField(.customFieldAdded)` adds a new linked custom field view and selects
    /// default `LinkedIdType`.
    @MainActor
    func test_customField_customFieldAdded_linked() {
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        subject.receive(.customField(.customFieldAdded(.linked, "linked field")))
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields[1].name, "linked field")
        XCTAssertEqual(subject.state.customFieldsState.customFields[1].type, .linked)
        XCTAssertNil(subject.state.customFieldsState.customFields[1].value)
        XCTAssertEqual(
            subject.state.customFieldsState.customFields[1].linkedIdType,
            LinkedIdType.getLinkedIdType(for: subject.state.customFieldsState.cipherType).first
        )
    }

    /// `receive(_:)` with `.customField(.customFieldChanged(newValue:,index:))` changes
    /// the value of the custom field.
    @MainActor
    func test_customField_customFieldChanged() {
        subject.receive(.customField(.customFieldChanged("newValue", index: 0)))
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "newValue")
    }

    /// `receive(_:)` with `.customField(.customFieldNameChanged)` changes the name of the custom field.
    @MainActor
    func test_customField_customFieldNameChanged() {
        subject.receive(.customField(.customFieldNameChanged(index: 0, newValue: "newFieldName")))
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "newFieldName")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "old")
    }

    /// `receive(_:)` with `customField(.editCustomFieldNamePressed(index:))` navigates
    /// to the `.alert` route to edit the existing custom field name .
    @MainActor
    func test_receive_editCustomFieldNamePressed() async throws {
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.name, "fieldName1")
        subject.receive(.customField(.editCustomFieldNamePressed(index: 0)))
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .nameCustomFieldAlert { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "name", text: "new field name")
        let okAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.ok }))
        await okAction.handler?(okAction, [textField])
        // validate a new custom field was added to the state.
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.name, "new field name")
    }

    /// `receive(_:)` with `.customField(.moveDownCustomFieldPressed(index:))` move down
    /// the index of the given custom field.
    @MainActor
    func test_customField_moveDownCustomFieldPressed() {
        let originalCustomFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .hidden,
                value: "value1"
            ),
            CustomFieldState(
                name: "fieldName2",
                type: .text,
                value: "value2"
            ),
        ]

        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "value1")

        // move down the first custom field and validate the state change.
        subject.receive(.customField(.moveDownCustomFieldPressed(index: 0)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields.reversed())
    }

    /// `receive(_:)` with `.customField(.moveDownCustomFieldPressed(index:))` will not
    ///  change anything if the the given index to move down was wrong.
    @MainActor
    func test_customField_moveDownCustomFieldPressed_wrongIndexes() {
        let originalCustomFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .hidden,
                value: "value1"
            ),
            CustomFieldState(
                name: "fieldName2",
                type: .text,
                value: "value2"
            ),
        ]

        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "value1")

        // test wrong indexes for move down custom field.
        subject.receive(.customField(.moveDownCustomFieldPressed(index: 2)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)

        subject.receive(.customField(.moveDownCustomFieldPressed(index: 1)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)

        subject.receive(.customField(.moveDownCustomFieldPressed(index: -1)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)
    }

    /// `receive(_:)` with `.customField(.moveUpCustomFieldPressed(index:))` move up
    /// the index of the given custom field.
    @MainActor
    func test_customField_moveUpCustomFieldPressed() {
        let originalCustomFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .hidden,
                value: "value1"
            ),
            CustomFieldState(
                name: "fieldName2",
                type: .text,
                value: "value2"
            ),
        ]

        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields[0].name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields[0].type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields[0].value, "value1")

        // move up the second custom field and validate the state change.
        subject.receive(.customField(.moveUpCustomFieldPressed(index: 1)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields.reversed())
    }

    /// `receive(_:)` with `.customField(.moveUpCustomFieldPressed(index:))` will not change anything if
    /// the the given index to move up was wrong.
    @MainActor
    func test_customField_moveUpCustomFieldPressed_wrongIndexes() {
        let originalCustomFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .hidden,
                value: "value1"
            ),
            CustomFieldState(
                name: "fieldName2",
                type: .text,
                value: "value2"
            ),
        ]

        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "value1")

        // test wrong indexes for move down custom field.
        subject.receive(.customField(.moveUpCustomFieldPressed(index: 2)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)

        subject.receive(.customField(.moveUpCustomFieldPressed(index: 0)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)

        subject.receive(.customField(.moveUpCustomFieldPressed(index: -1)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)
    }

    /// `receive(_:)` with `customField(.newCustomFieldPressed)` navigates to the `.alert` route
    /// to select the new custom field type.
    @MainActor
    func test_receive_newCustomFieldPressed() async throws {
        subject.receive(.customField(.newCustomFieldPressed))

        // Validate that select custom field type action sheet is shown.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions.count, 5)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.fieldTypeText)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.fieldTypeHidden)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.fieldTypeBoolean)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.fieldTypeLinked)
        XCTAssertEqual(alert.alertActions[4].title, Localizations.cancel)
    }

    /// `receive(_:)` with `customField(.newCustomFieldPressed)` navigates to the `.alert` route
    /// to select the new custom field type for secure note.
    @MainActor
    func test_receive_newCustomFieldPressed_forSecureNote() async throws {
        subject.state.type = .secureNote
        subject.receive(.customField(.newCustomFieldPressed))

        // Validate that select custom field type action sheet is shown.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions.count, 4)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.fieldTypeText)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.fieldTypeHidden)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.fieldTypeBoolean)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.cancel)
    }

    /// `receive(_:)` with `customField(.newCustomFieldPressed)` navigates to the `.alert` route
    /// to select the new custom field type for SSH key.
    @MainActor
    func test_receive_newCustomFieldPressed_forSSHKey() async throws {
        subject.state.type = .sshKey
        subject.receive(.customField(.newCustomFieldPressed))

        // Validate that select custom field type action sheet is shown.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.alertActions.count, 4)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.fieldTypeText)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.fieldTypeHidden)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.fieldTypeBoolean)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.cancel)
    }

    /// `receive(_:)` with `.customField(.removeCustomFieldPressed(index:))` will remove
    /// the  custom field from given index.
    @MainActor
    func test_customField_removeCustomFieldPressed() {
        let originalCustomFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .hidden,
                value: "value1"
            ),
            CustomFieldState(
                name: "fieldName2",
                type: .text,
                value: "value2"
            ),
        ]

        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "value1")

        subject.receive(.customField(.removeCustomFieldPressed(index: 1)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, [originalCustomFields[0]])

        subject.receive(.customField(.removeCustomFieldPressed(index: 0)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, [])
    }

    /// `receive(_:)` with `.customField(.removeCustomFieldPressed(index:))` will not change anything
    /// if  given index was wrong.
    @MainActor
    func test_customField_removeCustomFieldPressed_wrongIndexes() {
        let originalCustomFields = [
            CustomFieldState(
                name: "fieldName1",
                type: .hidden,
                value: "value1"
            ),
            CustomFieldState(
                name: "fieldName2",
                type: .text,
                value: "value2"
            ),
        ]

        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.value, "value1")

        subject.receive(.customField(.removeCustomFieldPressed(index: -1)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)

        subject.receive(.customField(.removeCustomFieldPressed(index: 2)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)

        subject.receive(.customField(.removeCustomFieldPressed(index: 3)))
        XCTAssertEqual(subject.state.customFieldsState.customFields, originalCustomFields)
    }

    /// `receive(_:)` with `customField(.selectedCustomFieldType)` navigates to the `.alert` route
    /// to name the new custom field.
    @MainActor
    func test_customField_selectedCustomFieldType() async throws {
        subject.receive(.customField(.selectedCustomFieldType(.boolean)))

        // Validate that the new custom field name alert is shown.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .nameCustomFieldAlert { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "name", text: "field name")
        let okAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.ok }))
        await okAction.handler?(okAction, [textField])
        // validate a new custom field was added to the state.
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 2)
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.name, "field name")
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.type, .boolean)
    }

    /// `receive(_:)` with `customField(.selectedLinkedIdType)` updates
    /// the `.linkedIdType` of the custom field.
    @MainActor
    func test_customField_selectedLinkedIdType() async throws {
        let originalCustomFields = [
            CustomFieldState(
                linkedIdType: .loginPassword,
                name: "fieldName1",
                type: .linked,
                value: nil
            ),
        ]
        subject.state.customFieldsState.customFields = originalCustomFields
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.type, .linked)
        XCTAssertNil(subject.state.customFieldsState.customFields.last?.value)
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.linkedIdType, .loginPassword)

        subject.receive(.customField(.selectedLinkedIdType(0, .loginUsername)))
        XCTAssertEqual(subject.state.customFieldsState.customFields.last?.linkedIdType, .loginUsername)
    }

    /// `receive(_:)` with `customField(.togglePasswordVisibilityChanged)`  only changes
    /// the `isPasswordVisible` of the custom field.
    @MainActor
    func test_customField_togglePasswordVisibilityChanged() async throws {
        XCTAssertEqual(subject.state.customFieldsState.customFields[0].isPasswordVisible, false)
        subject.receive(.customField(.togglePasswordVisibilityChanged(true, 0)))
        XCTAssertEqual(subject.state.customFieldsState.customFields.count, 1)
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.name, "fieldName1")
        XCTAssertEqual(subject.state.customFieldsState.customFields.first?.type, .hidden)
        XCTAssertEqual(subject.state.customFieldsState.customFields[0].isPasswordVisible, true)
    }

    /// `didCancelGenerator()` navigates to the `.dismiss()` route.
    @MainActor
    func test_didCancelGenerator() {
        subject.didCancelGenerator()
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `didCompleteGenerator` with a passphrase value updates the state with the new password value
    /// and navigates to the `.dismiss()` route.
    @MainActor
    func test_didCompleteGenerator_withPassphrase() {
        subject.state.loginState.username = "username123"
        subject.state.loginState.password = "password123"
        subject.didCompleteGenerator(for: .passphrase, with: "passphrase")
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(subject.state.loginState.password, "passphrase")
        XCTAssertEqual(subject.state.loginState.username, "username123")
    }

    /// `didCompleteGenerator` with a password value updates the state with the new password value
    /// and navigates to the `.dismiss()` route.
    @MainActor
    func test_didCompleteGenerator_withPassword() {
        subject.state.loginState.username = "username123"
        subject.state.loginState.password = "password123"
        subject.didCompleteGenerator(for: .password, with: "password")
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(subject.state.loginState.password, "password")
        XCTAssertEqual(subject.state.loginState.username, "username123")
    }

    /// `didCompleteGenerator` with a username value updates the state with the new username value
    /// and navigates to the `.dismiss()` route.
    @MainActor
    func test_didCompleteGenerator_withUsername() {
        subject.state.loginState.username = "username123"
        subject.state.loginState.password = "password123"
        subject.didCompleteGenerator(for: .username, with: "email@example.com")
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(subject.state.loginState.username, "email@example.com")
        XCTAssertEqual(subject.state.loginState.password, "password123")
    }

    /// `didCompleteCapture` with a value updates the state with the new auth key value
    /// and navigates to the `.dismiss` route.
    @MainActor
    func test_didCompleteCapture_failure() {
        subject.state.loginState.totpState = .none
        totpService.getTOTPConfigResult = .failure(TOTPServiceError.invalidKeyFormat)
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteCapture(captureCoordinator.asAnyCoordinator(), with: "1234")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertEqual(
            coordinator.alertShown.last,
            Alert(
                title: Localizations.authenticatorKeyReadError,
                message: nil,
                alertActions: [
                    AlertAction(title: Localizations.ok, style: .default),
                ]
            )
        )
        XCTAssertEqual(subject.state.loginState.authenticatorKey, "")
        XCTAssertNil(subject.state.toast)
    }

    /// `didCompleteCapture` with a value updates the state with the new auth key value
    /// and navigates to the `.dismiss()` route.
    @MainActor
    func test_didCompleteCapture_success() throws {
        subject.state.loginState.totpState = .none
        let key = String.standardTotpKey
        let keyConfig = TOTPKeyModel(authenticatorKey: key)
        totpService.getTOTPConfigResult = .success(keyConfig)
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteCapture(captureCoordinator.asAnyCoordinator(), with: key)
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertEqual(subject.state.loginState.authenticatorKey, .standardTotpKey)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.authenticatorKeyAdded))
    }

    /// `didMoveCipher(_:to:)` displays a toast after the cipher is moved to the organization.
    @MainActor
    func test_didMoveCipher() {
        subject.didMoveCipher(.fixture(name: "Bitwarden Password"), to: .organization(id: "1", name: "Organization"))

        waitFor { subject.state.toast != nil }

        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.movedItemToOrg("Bitwarden Password", "Organization"))
        )
    }

    /// `didUpdateCipher()` displays a toast after the cipher is updated.
    @MainActor
    func test_didUpdateCipher() {
        subject.didUpdateCipher()

        waitFor { subject.state.toast != nil }

        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.itemUpdated))
    }

    /// `folderAdded(_:)` sets the selected folder to the folder that was added.
    @MainActor
    func test_folderAdded() {
        let newFolder = FolderView.fixture(name: "New folder")
        subject.state.folders = [.default, .custom(newFolder)]

        subject.folderAdded(newFolder)

        XCTAssertEqual(subject.state.folder, .custom(newFolder))
    }

    /// `init(appExtensionDelegate:coordinator:delegate:services:state:)` with adding configuration
    /// doesn't add itself as a rehydratable target.
    @MainActor
    func test_init_addingConfiguration() {
        rehydrationHelper.rehydratableTargets.removeAll()

        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                addItem: .login,
                hasPremium: false
            )
        )
        XCTAssertTrue(rehydrationHelper.rehydratableTargets.isEmpty)
    }

    /// `init(appExtensionDelegate:coordinator:delegate:services:state:)` with editing configuration
    /// doesn't add itself as a rehydratable target.
    @MainActor
    func test_init_editingConfiguration() {
        rehydrationHelper.rehydratableTargets.removeAll()

        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                rehydrationHelper: rehydrationHelper,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                existing: CipherView.fixture(),
                hasPremium: false
            )!
        )
        waitFor(
            !rehydrationHelper.rehydratableTargets.isEmpty
                && rehydrationHelper.rehydratableTargets[0] is AddEditItemProcessor
        )
    }

    /// `perform(_:)` with `.appeared` doesn't show the password autofill alert if it has already been shown.
    @MainActor
    func test_perform_appeared_showPasswordAutofill_alreadyShown() async {
        stateService.addSitePromptShown = true
        await subject.perform(.appeared)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.appeared` doesn't show the password autofill alert if it's in the extension.
    @MainActor
    func test_perform_appeared_showPasswordAutofill_extension() async {
        appExtensionDelegate.isInAppExtension = true
        await subject.perform(.appeared)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.appeared` doesn't show the password autofill alert if the user isn't adding a login.
    @MainActor
    func test_perform_appeared_showPasswordAutofill_nonLoginType() async {
        subject.state.type = .card
        await subject.perform(.appeared)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.appeared` shows the password autofill alert.
    @MainActor
    func test_perform_appeared_showPasswordAutofill_notShown() async {
        await subject.perform(.appeared)
        XCTAssertEqual(coordinator.alertShown.last, .passwordAutofillInformation())
        XCTAssertTrue(stateService.addSitePromptShown)
    }

    /// `perform(:)` with `.appeared` should set the `isLearnNewLoginActionCardEligible` to `true`
    /// if the `learnNewLoginActionCardStatus` is `incomplete`.
    @MainActor
    func test_perform_checkLearnNewLoginActionCardEligibility() async {
        stateService.learnNewLoginActionCardStatus = .incomplete
        subject = AddEditItemProcessor(
            appExtensionDelegate: nil,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                configService: configService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                rehydrationHelper: rehydrationHelper,
                reviewPromptService: reviewPromptService,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                customFields: [
                    CustomFieldState(
                        name: "fieldName1",
                        type: .hidden,
                        value: "old"
                    ),
                ],
                hasPremium: true
            )
        )
        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.isLearnNewLoginActionCardEligible)
    }

    /// `perform(:)` with `.appeared` should not set the `isLearnNewLoginActionCardEligible` to `true`
    /// if app is in iOS extension flow.
    @MainActor
    func test_perform_checkLearnNewLoginActionCardEligibility_false_iOSExtension() async {
        stateService.learnNewLoginActionCardStatus = .incomplete
        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                configService: configService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                rehydrationHelper: rehydrationHelper,
                reviewPromptService: reviewPromptService,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                customFields: [
                    CustomFieldState(
                        name: "fieldName1",
                        type: .hidden,
                        value: "old"
                    ),
                ],
                hasPremium: true
            )
        )
        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.isLearnNewLoginActionCardEligible)
    }

    /// `perform(_:)` with `.appeared` checks if user has masterpassword.
    @MainActor
    func test_perform_appeared_checkUserHasMasterPassword_true() async {
        authRepository.hasMasterPasswordResult = .success(true)
        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.showMasterPasswordReprompt)
    }

    /// `perform(_:)` with `.appeared` checks if user has masterpassword.
    @MainActor
    func test_perform_appeared_checkUserHasMasterPassword_false() async {
        authRepository.hasMasterPasswordResult = .success(false)
        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.showMasterPasswordReprompt)
    }

    /// `perform` with `.checkPasswordPressed` checks the password with the HIBP service.
    @MainActor
    func test_perform_checkPasswordPressed_exposedPassword() async throws {
        subject.state.loginState.password = "password1234"
        client.result = .httpSuccess(testData: .hibpLeakedPasswords)

        await subject.perform(.checkPasswordPressed)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/e6b6a"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.passwordExposed(1957),
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        ))
    }

    /// `perform` with `.checkPasswordPressed` checks the password with the HIBP service.
    @MainActor
    func test_perform_checkPasswordPressed_safePassword() async throws {
        subject.state.loginState.password = "iqpeor,kmn!JO8932jldfasd"
        client.result = .httpSuccess(testData: .hibpLeakedPasswords)

        await subject.perform(.checkPasswordPressed)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://api.pwnedpasswords.com/range/c3ed8"))
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.passwordSafe,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        ))
    }

    /// Tapping the copy button on the auth key row dispatches the `.copyPassword` action.
    @MainActor
    func test_perform_copyTotp() async throws {
        subject.state.loginState.totpState = LoginTOTPState("JBSWY3DPEHPK3PXP")

        await subject.perform(.copyTotpPressed)
        XCTAssertEqual(
            subject.state.loginState.authenticatorKey,
            pasteboardService.copiedString
        )
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// generic error alert if soft deleting fails.
    @MainActor
    func test_perform_deletePressed_genericError() async throws {
        subject.state = CipherItemState(existing: .fixture(id: "123"), hasPremium: false)!
        struct TestError: Error, Equatable {}
        vaultRepository.softDeleteCipherResult = .failure(TestError())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: true) {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        // Ensure the generic error alert is displayed.
        XCTAssertEqual(coordinator.errorAlertsShown as? [TestError], [TestError()])
        XCTAssertEqual(errorReporter.errors.first as? TestError, TestError())
    }

    /// `perform(_:)` with `.deletePressed` presents the confirmation alert before delete the item and displays
    /// toast if soft deleting succeeds.
    @MainActor
    func test_perform_deletePressed_success() async throws {
        subject.state = CipherItemState(
            existing: .fixture(id: "123"),
            hasPremium: false
        )!
        vaultRepository.softDeleteCipherResult = .success(())
        await subject.perform(.deletePressed)
        // Ensure the alert is shown.
        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert, .deleteCipherConfirmation(isSoftDelete: true) {})

        // Tap the "Yes" button on the alert.
        let action = try XCTUnwrap(alert?.alertActions.first(where: { $0.title == Localizations.yes }))
        await action.handler?(action, [])

        XCTAssertNil(errorReporter.errors.first)
        // Ensure the cipher is deleted and the view is dismissed.
        let deletedCipher: CipherView = .fixture(id: "123")
        XCTAssertEqual(
            vaultRepository.softDeletedCipher.last?.id,
            deletedCipher.id
        )
        XCTAssertEqual(
            vaultRepository.softDeletedCipher.last,
            deletedCipher
        )
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = coordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        XCTAssertTrue(delegate.itemSoftDeletedCalled)
    }

    /// `perform(_:)` with `.dismissNewLoginActionCard` will set `.showLearnNewLoginActionCard` to false
    /// and updates `.learnNewLoginActionCardShown` via  stateService.
    @MainActor
    func test_perform_dismissNewLoginActionCard() async {
        subject.state.isLearnNewLoginActionCardEligible = true
        await subject.perform(.dismissNewLoginActionCard)
        XCTAssertFalse(subject.state.isLearnNewLoginActionCardEligible)
        XCTAssertEqual(stateService.learnNewLoginActionCardStatus, .complete)
    }

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership options for a cipher from the repository.
    @MainActor
    func test_perform_fetchCipherOptions() async {
        let collections: [CollectionView] = [
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ]

        vaultRepository.fetchCipherOwnershipOptions = [.personal(email: "user@bitwarden.com")]
        vaultRepository.fetchCollectionsResult = .success(collections)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.allUserCollections, collections)
        XCTAssertEqual(subject.state.ownershipOptions, [.personal(email: "user@bitwarden.com")])
        try XCTAssertTrue(XCTUnwrap(vaultRepository.fetchCollectionsIncludeReadOnly))

        XCTAssertNil(eventService.collectCipherId)
        XCTAssertNil(eventService.collectEventType)
    }

    /// `perform(_:)` with `.fetchCipherOptions` handles errors.
    @MainActor
    func test_perform_fetchCipherOptions_error() async {
        vaultRepository.fetchCipherOwnershipOptions = [.personal(email: "user@bitwarden.com")]
        vaultRepository.fetchCollectionsResult = .failure(BitwardenTestError.example)
        vaultRepository.fetchFoldersResult = .failure(BitwardenTestError.example)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.allUserCollections, [])
        XCTAssertEqual(subject.state.folders, [])
        XCTAssertEqual(subject.state.ownershipOptions, [])

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `.fetchCipherOptions` sends events on edit.
    @MainActor
    func test_perform_fetchCipherOptions_events() async {
        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                existing: CipherView.fixture(id: "100"),
                hasPremium: true
            )!
        )
        let collections: [CollectionView] = [
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ]

        vaultRepository.fetchCipherOwnershipOptions = [.personal(email: "user@bitwarden.com")]
        vaultRepository.fetchCollectionsResult = .success(collections)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.allUserCollections, collections)
        XCTAssertEqual(subject.state.ownershipOptions, [.personal(email: "user@bitwarden.com")])
        try XCTAssertTrue(XCTUnwrap(vaultRepository.fetchCollectionsIncludeReadOnly))

        XCTAssertEqual(eventService.collectCipherId, "100")
        XCTAssertEqual(eventService.collectEventType, .cipherClientViewed)
    }

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership options for a cipher and
    /// filters out any preset collections that the user doesn't have access to.
    @MainActor
    func test_perform_fetchCipherOptions_filtersUnavailableCollections() async {
        let owner = CipherOwner.organization(id: "123", name: "Test Org 1")
        subject.state = CipherItemState(
            collectionIds: ["1", "2"],
            hasPremium: false,
            organizationId: owner.organizationId
        )
        vaultRepository.fetchCipherOwnershipOptions = [owner]
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(id: "2", name: "Engineering"),
        ])

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.collectionIds, ["2"])
        XCTAssertEqual(subject.state.owner, owner)
    }

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership options for a cipher and
    /// filters out any preset collections that the user only has read-only access to.
    @MainActor
    func test_perform_fetchCipherOptions_filtersReadOnlyCollections() async {
        let owner = CipherOwner.organization(id: "123", name: "Test Org 1")
        subject.state = CipherItemState(
            collectionIds: ["1", "2"],
            hasPremium: false,
            organizationId: owner.organizationId
        )
        vaultRepository.fetchCipherOwnershipOptions = [owner]
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(id: "1", name: "Design", readOnly: true),
            .fixture(id: "2", name: "Engineering"),
        ])

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.collectionIds, ["2"])
        XCTAssertEqual(subject.state.owner, owner)
    }

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership options for a cipher from the repository
    /// when the personal ownership policy is in place.
    @MainActor
    func test_perform_fetchCipherOptions_personalOwnershipPolicy_enabled() async throws {
        let collections: [CollectionView] = [
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ]

        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: "123", name: "Test Org 1"),
            .organization(id: "987", name: "Test Org 2"),
        ]
        vaultRepository.fetchCollectionsResult = .success(collections)

        policyService.policyAppliesToUserResult[.personalOwnership] = true

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.collectionIds, [])
        XCTAssertEqual(subject.state.allUserCollections, collections)
        XCTAssertEqual(subject.state.organizationId, "123")
        XCTAssertEqual(subject.state.ownershipOptions, [
            .organization(id: "123", name: "Test Org 1"),
            .organization(id: "987", name: "Test Org 2"),
        ])
        try XCTAssertTrue(XCTUnwrap(vaultRepository.fetchCollectionsIncludeReadOnly))
        try XCTAssertFalse(XCTUnwrap(vaultRepository.fetchCipherOwnershipOptionsIncludePersonal))
    }

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership and policy options for a
    /// cipher, but doesn't overwrite the owner if it was previously set to an organization and the
    /// personal ownership policy is in effect.
    @MainActor
    func test_perform_fetchCipherOptions_personalOwnershipPolicy_doesNotOverrideOwner() async {
        let owner = CipherOwner.organization(id: "987", name: "Test Org 2")
        subject.state = CipherItemState(
            collectionIds: ["1"],
            hasPremium: false,
            organizationId: owner.organizationId
        )

        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: "123", name: "Test Org 1"),
            .organization(id: "987", name: "Test Org 2"),
        ]
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ])

        policyService.policyAppliesToUserResult[.personalOwnership] = true

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.collectionIds, ["1"])
        XCTAssertEqual(subject.state.owner, owner)
    }

    /// `perform(_:)` with `.fetchCipherOptions` includes read-only collections
    /// so that the state can properly compute if it's deletable
    @MainActor
    func test_perform_fetchCipherOptions_readonly() async {
        let owner = CipherOwner.organization(id: "123", name: "Test Org")
        subject.state = CipherItemState(
            collectionIds: ["1"],
            hasPremium: false,
            organizationId: owner.organizationId
        )

        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: "123", name: "Test Org"),
        ]
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(id: "1", name: "Design", manage: false),
        ])

        await subject.perform(.fetchCipherOptions)

        try XCTAssertTrue(XCTUnwrap(vaultRepository.fetchCollectionsIncludeReadOnly))
        XCTAssertEqual(subject.state.allUserCollections.map(\.id), ["1"])
        XCTAssertEqual(subject.state.collectionIds, ["1"])
        XCTAssertEqual(subject.state.owner, owner)
        XCTAssertFalse(subject.state.canBeDeleted)
        XCTAssertTrue(subject.state.canAssignToCollection)
    }

    /// `perform(_:)` with `.savePressed` displays an alert if name field is invalid.
    @MainActor
    func test_perform_savePressed_invalidName() async throws {
        subject.state.name = "    "

        await subject.perform(.savePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.validationFieldRequired(Localizations.name),
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
    }

    /// `perform(_:)` with `.savePressed` displays an alert if saving or updating fails.
    @MainActor
    func test_perform_savePressed_genericErrorAlert() async throws {
        subject.state.name = "vault item"
        struct EncryptError: Error, Equatable {}
        vaultRepository.addCipherResult = .failure(EncryptError())

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.errorAlertsShown as? [EncryptError], [EncryptError()])
    }

    /// `perform(_:)` with `.savePressed` shows an error if an organization but no collections have been selected.
    @MainActor
    func test_perform_savePressed_noCollection() async throws {
        subject.state.name = "Organization Item"
        subject.state.owner = CipherOwner.organization(id: "123", name: "Organization")

        await subject.perform(.savePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.selectOneCollection
            )
        )
    }

    /// `perform(_:)` with `.savePressed` succeeds if an organization and collection have been selected.
    @MainActor
    func test_perform_savePressed_organizationAndCollection() async throws {
        subject.state.name = "Organization Item"
        subject.state.owner = CipherOwner.organization(id: "123", name: "Organization")
        subject.state.collectionIds = ["1"]

        await subject.perform(.savePressed)

        XCTAssertNotNil(vaultRepository.addCipherCiphers.first)
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `perform(_:)` with `.savePressed` displays an alert containing the message returned by the
    /// server if saving fails.
    @MainActor
    func test_perform_savePressed_serverErrorAlert() async throws {
        let response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)
        let error = try ServerError.error(errorResponse: ErrorResponseModel(response: response))
        vaultRepository.addCipherResult = .failure(error)
        subject.state.name = "vault item"
        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.errorAlertsShown as? [ServerError], [error])
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    @MainActor
    func test_perform_savePressed_secureNote() async {
        subject.state.type = .secureNote
        subject.state.name = "secureNote"

        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).type,
            .secureNote
        )

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).name,
            "secureNote"
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(reviewPromptService.userActions, [.addedNewItem])
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    @MainActor
    func test_perform_savePressed_card() async throws {
        subject.state.name = "vault item"
        subject.state.type = .card
        let expectedCardState = CardItemState(
            brand: .custom(.visa),
            cardholderName: "Jane Doe",
            cardNumber: "12345",
            cardSecurityCode: "123",
            expirationMonth: .custom(.apr),
            expirationYear: "1234"
        )
        subject.state.cardItemState = expectedCardState
        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).creationDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )
        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).revisionDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )

        let added = try XCTUnwrap(vaultRepository.addCipherCiphers.first)
        XCTAssertNil(added.identity)
        XCTAssertNil(added.login)
        XCTAssertNil(added.secureNote)
        XCTAssertNil(added.sshKey)
        XCTAssertNotNil(added.card)
        XCTAssertEqual(added.cardItemState(), expectedCardState)
        let unwrappedState = try XCTUnwrap(subject.state as? CipherItemState)
        XCTAssertEqual(
            added,
            unwrappedState
                .newCipherView(
                    creationDate: vaultRepository.addCipherCiphers[0].creationDate
                )
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(reviewPromptService.userActions, [.addedNewItem])
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    @MainActor
    func test_perform_savePressed_login() async {
        subject.state.name = "vault item"
        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).creationDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )
        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).revisionDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )

        XCTAssertEqual(
            vaultRepository.addCipherCiphers,
            [
                (subject.state as? CipherItemState)?
                    .newCipherView(creationDate: vaultRepository.addCipherCiphers[0].creationDate),
            ]
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(reviewPromptService.userActions, [.addedNewItem])
    }

    /// `perform(_:)` with `.savePressed` saves the item for `.sshKey`.
    @MainActor
    func test_perform_savePressed_sshKey() async throws {
        subject.state.name = "vault item"
        subject.state.type = .sshKey
        let expectedSSHKeyItemState = SSHKeyItemState(
            canViewPrivateKey: true,
            isPrivateKeyVisible: false,
            privateKey: "privateKey",
            publicKey: "publicKey",
            keyFingerprint: "fingerprint"
        )
        subject.state.sshKeyState = expectedSSHKeyItemState
        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).creationDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )
        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).revisionDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )

        let added = try XCTUnwrap(vaultRepository.addCipherCiphers.first)
        XCTAssertNil(added.identity)
        XCTAssertNil(added.login)
        XCTAssertNil(added.secureNote)
        XCTAssertNotNil(added.sshKey)
        XCTAssertNil(added.card)
        XCTAssertEqual(added.sshKeyItemState(), expectedSSHKeyItemState)
        let unwrappedState = try XCTUnwrap(subject.state as? CipherItemState)
        XCTAssertEqual(
            added,
            unwrappedState
                .newCipherView(
                    creationDate: vaultRepository.addCipherCiphers[0].creationDate
                )
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertEqual(reviewPromptService.userActions, [.addedNewItem])
    }

    /// `perform(_:)` with `.savePressed` in the app extension completes the autofill request if a
    /// username and password was entered.
    @MainActor
    func test_perform_savePressed_appExtension() async {
        appExtensionDelegate.isInAppExtensionSaveLoginFlow = true
        subject.state.loginState.password = "PASSWORD"
        subject.state.loginState.username = "user@bitwarden.com"
        subject.state.name = "Login from App Extension"

        await subject.perform(.savePressed)

        XCTAssertFalse(vaultRepository.addCipherCiphers.isEmpty)

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(reviewPromptService.userActions, [.addedNewItem])
    }

    /// `perform(_:)` with `.savePressed` in the app extension cancels the autofill extension if no
    /// username or password was entered.
    @MainActor
    func test_perform_savePressed_appExtension_cancel() async {
        appExtensionDelegate.isInAppExtensionSaveLoginFlow = true
        subject.state.name = "Login from App Extension"

        await subject.perform(.savePressed)

        XCTAssertFalse(vaultRepository.addCipherCiphers.isEmpty)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `perform(_:)` with `.savePressed` forwards errors to the error reporter.
    @MainActor
    func test_perform_savePressed_error() async {
        subject.state.name = "vault item"
        struct EncryptError: Error, Equatable {}
        vaultRepository.addCipherResult = .failure(EncryptError())
        await subject.perform(.savePressed)

        XCTAssertEqual(errorReporter.errors.first as? EncryptError, EncryptError())
        XCTAssertTrue(reviewPromptService.userActions.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` notifies the delegate that the item was added and
    /// doesn't dismiss the view if it returns `false`.
    @MainActor
    func test_perform_savePressed_new_shouldNotDismiss() async throws {
        delegate.itemAddedShouldDismiss = false
        subject.state.name = "Bitwarden"

        await subject.perform(.savePressed)

        XCTAssertTrue(delegate.itemAddedCalled)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` forwards errors to the error reporter.
    @MainActor
    func test_perform_savePressed_existing_error() async throws {
        let cipher = CipherView.fixture(id: "123")
        let maybeCipherState = CipherItemState(
            existing: cipher,
            hasPremium: true
        )
        let cipherState = try XCTUnwrap(maybeCipherState)
        struct EncryptError: Error, Equatable {}
        vaultRepository.updateCipherResult = .failure(EncryptError())

        subject.state = cipherState.addEditState
        subject.state.name = "vault item"
        await subject.perform(.savePressed)

        XCTAssertEqual(errorReporter.errors.first as? EncryptError, EncryptError())
        XCTAssertTrue(reviewPromptService.userActions.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` notifies the delegate that the item was updated and
    /// doesn't dismiss the view if it returns `false`.
    @MainActor
    func test_perform_savePressed_existing_shouldNotDismiss() async throws {
        delegate.itemUpdatedShouldDismiss = false
        subject.state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))

        await subject.perform(.savePressed)

        XCTAssertTrue(delegate.itemUpdatedCalled)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    @MainActor
    func test_perform_savePressed_existing_success() async throws {
        let cipher = CipherView.fixture(id: "123")
        let maybeCipherState = CipherItemState(
            existing: cipher,
            hasPremium: true
        )
        let cipherState = try XCTUnwrap(maybeCipherState)
        vaultRepository.updateCipherResult = .success(())

        subject.state = cipherState.addEditState
        subject.state.name = "vault item"
        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.updateCipherCiphers.first).creationDate.timeIntervalSince1970,
            cipher.creationDate.timeIntervalSince1970,
            accuracy: 1
        )
        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.updateCipherCiphers.first).revisionDate.timeIntervalSince1970,
            cipher.revisionDate.timeIntervalSince1970,
            accuracy: 1
        )

        XCTAssertEqual(
            vaultRepository.updateCipherCiphers,
            [
                cipher.updatedView(with: subject.state),
            ]
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertTrue(reviewPromptService.userActions.isEmpty)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization authorized navigates to the
    /// `.setupTotpCamera` route.
    @MainActor
    func test_perform_setupTotpPressed_cameraAuthorizationAuthorized() async {
        cameraService.cameraAuthorizationStatus = .authorized
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.events.last, .showScanCode)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization denied navigates to the
    /// `.setupTotpManual` route.
    @MainActor
    func test_perform_setupTotpPressed_cameraAuthorizationDenied() async {
        cameraService.cameraAuthorizationStatus = .denied
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization restricted navigates to the
    /// `.setupTotpManual` route.
    @MainActor
    func test_perform_setupTotpPressed_cameraAuthorizationRestricted() async {
        cameraService.cameraAuthorizationStatus = .restricted
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
    }

    /// `perform(_:)` with `.setupTotpPressed` when in the app extension navigates to the
    /// `.setupTotpManual` route.
    @MainActor
    func test_perform_setupTotpPressed_extension() async {
        appExtensionDelegate.isInAppExtension = true
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
    }

    /// `perform(_:)` with `.showLearnNewLoginGuidedTour` sets `showLearnNewLoginActionCard` to `false`.
    @MainActor
    func test_perform_showLearnNewLoginGuidedTour() async {
        subject.state.isLearnNewLoginActionCardEligible = true
        await subject.perform(.showLearnNewLoginGuidedTour)
        XCTAssertFalse(subject.state.isLearnNewLoginActionCardEligible)
        XCTAssertEqual(stateService.learnNewLoginActionCardStatus, .complete)
        XCTAssertTrue(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `perform(_:)` with `.streamFolders` updates the state's list of folders whenever it changes.
    @MainActor
    func test_perform_streamFolders() {
        let task = Task {
            await subject.perform(.streamFolders)
        }
        defer { task.cancel() }

        let folders: [FolderView] = [
            .fixture(id: "1", name: "Social"),
            .fixture(id: "2", name: "Work"),
        ]
        settingsRepository.foldersListSubject.send(folders)

        waitFor(!subject.state.folders.isEmpty)

        XCTAssertEqual(
            subject.state.folders,
            [.default] + folders.map { .custom($0) }
        )
    }

    /// `perform(_:)` with `.streamFolders` logs an error if getting the list of folders fails.
    @MainActor
    func test_perform_streamLastSyncTime_error() async {
        settingsRepository.foldersListError = StateServiceError.noActiveAccount

        await subject.perform(.streamFolders)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `receive(_:)` with `.addFolder` navigates to the add folder view.
    @MainActor
    func test_receive_addFolder() {
        subject.receive(.addFolder)
        XCTAssertEqual(coordinator.routes, [.addFolder])
    }

    /// `receive(_:)` with `authKeyVisibilityTapped` updates the value in the state.
    @MainActor
    func test_receive_authKeyVisibilityTapped() {
        subject.state.loginState.isAuthKeyVisible = false
        subject.receive(.authKeyVisibilityTapped(true))

        XCTAssertTrue(subject.state.loginState.isAuthKeyVisible)
    }

    /// `receive(_:)` with `.backTapped` updates the guided tour state to the previous step.
    @MainActor
    func test_receive_backTapped() {
        subject.state.guidedTourViewState.currentIndex = 2

        subject.receive(.guidedTourViewAction(.backTapped))
        XCTAssertEqual(subject.state.guidedTourViewState.currentIndex, 1)
        XCTAssertEqual(subject.state.guidedTourViewState.currentStepState, .loginStep2)

        subject.receive(.guidedTourViewAction(.backTapped))
        XCTAssertEqual(subject.state.guidedTourViewState.currentIndex, 0)
        XCTAssertEqual(subject.state.guidedTourViewState.currentStepState, .loginStep1)
    }

    /// `receive(_:)` with `.clearTOTPKey` clears the authenticator key.
    @MainActor
    func test_receive_clearTOTPKey() {
        subject.state.loginState.totpState = LoginTOTPState(.standardTotpKey)
        subject.receive(.totpKeyChanged(nil))

        XCTAssertEqual(subject.state.loginState.authenticatorKey, "")
    }

    /// `receive(_:)` with `.removePasskeyPressed` clears the fido2Credentials.
    @MainActor
    func test_receive_removePasskeyPressed() {
        subject.state.loginState.fido2Credentials = [
            .fixture(creationDate: Date(timeIntervalSince1970: 1_710_494_110)),
        ]
        subject.receive(.removePasskeyPressed)

        XCTAssertEqual(subject.state.loginState.fido2Credentials, [])
    }

    /// `receive(_:)` with `.collectionToggleChanged` updates the selected collection IDs for the cipher.
    @MainActor
    func test_receive_collectionToggleChanged() {
        subject.state.allUserCollections = [
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ]

        subject.receive(.collectionToggleChanged(true, collectionId: "1"))
        XCTAssertEqual(subject.state.collectionIds, ["1"])

        subject.receive(.collectionToggleChanged(true, collectionId: "2"))
        XCTAssertEqual(subject.state.collectionIds, ["1", "2"])

        subject.receive(.collectionToggleChanged(false, collectionId: "1"))
        XCTAssertEqual(subject.state.collectionIds, ["2"])
    }

    /// `receive(_:)` with `.guidedTourViewAction(.didRenderViewToSpotlight)` updates `.spotlightRegion`.
    @MainActor
    func test_receive_didRenderViewToSpotlight() {
        subject.receive(
            .guidedTourViewAction(
                .didRenderViewToSpotlight(frame: step1Spotlight, step: .step1)
            )
        )

        XCTAssertEqual(
            subject.state.guidedTourViewState.guidedTourStepStates[0].spotlightRegion,
            step1Spotlight
        )
    }

    /// `receive(_:)` with `.guidedTourViewAction(.dismissTapped)` dismisses the guided tour.
    @MainActor
    func test_receive_dismissTapped() {
        subject.receive(.guidedTourViewAction(.dismissTapped))
        XCTAssertFalse(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.dismiss()` navigates to the `.dismiss()` route.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `receive(_:)` with `.guidedTourViewAction(.doneTapped)` completes the guided tour.
    @MainActor
    func test_receive_doneTapped() {
        subject.receive(.guidedTourViewAction(.doneTapped))
        XCTAssertFalse(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.favoriteChanged` with `true` updates the state correctly.
    @MainActor
    func test_receive_favoriteChanged_withTrue() {
        subject.state.isFavoriteOn = false

        subject.receive(.favoriteChanged(true))
        XCTAssertTrue(subject.state.isFavoriteOn)

        subject.receive(.favoriteChanged(true))
        XCTAssertTrue(subject.state.isFavoriteOn)
    }

    /// `receive(_:)` with `.favoriteChanged` with `false` updates the state correctly.
    @MainActor
    func test_receive_favoriteChanged_withFalse() {
        subject.state.isFavoriteOn = true

        subject.receive(.favoriteChanged(false))
        XCTAssertFalse(subject.state.isFavoriteOn)

        subject.receive(.favoriteChanged(false))
        XCTAssertFalse(subject.state.isFavoriteOn)
    }

    /// `receive(_:)` with `.folderChanged` with a value updates the state correctly.
    @MainActor
    func test_receive_folderChanged_withValue() {
        let folder = FolderView.fixture(id: "1", name: "📁")
        subject.state.folders = [
            .default,
            .custom(folder),
            .custom(.fixture(id: "2", name: "💾")),
        ]
        subject.receive(.folderChanged(.custom(folder)))

        XCTAssertEqual(subject.state.folder, .custom(folder))
        XCTAssertEqual(subject.state.folderId, "1")
    }

    /// `receive(_:)` with `.folderChanged` without a value updates the state correctly.
    @MainActor
    func test_receive_folderChanged_withoutValue() {
        subject.state.folders = [
            .default,
            .custom(.fixture(id: "1", name: "📁")),
            .custom(.fixture(id: "2", name: "💾")),
        ]
        subject.state.folderId = "1"

        subject.receive(.folderChanged(.default))

        XCTAssertEqual(subject.state.folder, .default)
        XCTAssertNil(subject.state.folderId)
    }

    /// `receive(_:)` with `.generatePasswordPressed` navigates to the `.generator` route.
    @MainActor
    func test_receive_generatePasswordPressed() {
        subject.state.loginState.password = ""
        subject.receive(.generatePasswordPressed)

        XCTAssertEqual(coordinator.routes.last, .generator(.password))
    }

    /// `receive(_:)` with `.generateUsernamePressed` and with a password value in the state
    /// navigates to the `.alert` route.
    @MainActor
    func test_receive_generatePasswordPressed_withUsernameValue() async throws {
        subject.state.loginState.password = "password"
        subject.receive(.generatePasswordPressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.passwordOverrideAlert)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 2)

        XCTAssertEqual(alert.alertActions[0].title, Localizations.no)
        XCTAssertEqual(alert.alertActions[0].style, .default)
        XCTAssertNil(alert.alertActions[0].handler)

        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].style, .default)
        XCTAssertNotNil(alert.alertActions[1].handler)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.routes.last, .generator(.password))
    }

    /// `receive(_:)` with `.generateUsernamePressed` and without a username value in the state
    /// navigates to the `.generator` route.
    @MainActor
    func test_receive_generateUsernamePressed_withoutUsernameValue() {
        subject.state.loginState.username = ""
        subject.receive(.generateUsernamePressed)

        XCTAssertEqual(coordinator.routes.last, .generator(.username))
    }

    /// `receive(_:)` with `.generateUsernamePressed` and with a username value in the state
    /// navigates to the `.alert` route.
    @MainActor
    func test_receive_generateUsernamePressed_withUsernameValue() async throws {
        subject.state.loginState.username = "username"
        subject.receive(.generateUsernamePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.areYouSureYouWantToOverwriteTheCurrentUsername)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 2)

        XCTAssertEqual(alert.alertActions[0].title, Localizations.no)
        XCTAssertEqual(alert.alertActions[0].style, .default)
        XCTAssertNil(alert.alertActions[0].handler)

        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].style, .default)
        XCTAssertNotNil(alert.alertActions[1].handler)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.routes.last, .generator(.username))
    }

    /// `receive(_:)` with `.generateUsernamePressed` passes the host of the first URI to the generator.
    @MainActor
    func test_receive_generateUsernamePressed_withURI() async throws {
        subject.state.loginState.uris = [
            UriState(uri: "https://bitwarden.com"),
            UriState(uri: "https://example.com"),
        ]
        subject.receive(.generateUsernamePressed)
        XCTAssertEqual(coordinator.routes.last, .generator(.username, emailWebsite: "bitwarden.com"))

        subject.state.loginState.uris = [UriState(uri: "bitwarden.com")]
        subject.receive(.generateUsernamePressed)
        XCTAssertEqual(coordinator.routes.last, .generator(.username, emailWebsite: "bitwarden.com"))
    }

    /// `receive(_:)` with `.masterPasswordRePromptChanged` with `true` updates the state correctly.
    @MainActor
    func test_receive_masterPasswordRePromptChanged_withTrue() {
        subject.state.isMasterPasswordRePromptOn = false

        subject.receive(.masterPasswordRePromptChanged(true))
        XCTAssertTrue(subject.state.isMasterPasswordRePromptOn)

        subject.receive(.masterPasswordRePromptChanged(true))
        XCTAssertTrue(subject.state.isMasterPasswordRePromptOn)
    }

    /// `receive(_:)` with `.masterPasswordRePromptChanged` with `false` updates the state correctly.
    @MainActor
    func test_receive_masterPasswordRePromptChanged_withFalse() {
        subject.state.isMasterPasswordRePromptOn = true

        subject.receive(.masterPasswordRePromptChanged(false))
        XCTAssertFalse(subject.state.isMasterPasswordRePromptOn)

        subject.receive(.masterPasswordRePromptChanged(false))
        XCTAssertFalse(subject.state.isMasterPasswordRePromptOn)
    }

    /// `receive(_:)` with `.morePressed(.attachments)` navigates the user to the attachments  view.
    @MainActor
    func test_receive_morePressed_attachments() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state = try XCTUnwrap(
            CipherItemState(
                existing: cipher,
                hasPremium: true
            )
        )
        subject.receive(.morePressed(.attachments))
        XCTAssertEqual(coordinator.routes.last, .attachments(cipher))
    }

    /// `receive(_:)` with `.morePressed(.editCollections)` navigates the user to the edit
    /// collections view.
    @MainActor
    func test_receive_morePressed_editCollections() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state = try XCTUnwrap(
            CipherItemState(
                existing: cipher,
                hasPremium: true
            )
        )

        subject.receive(.morePressed(.editCollections))

        XCTAssertEqual(coordinator.routes.last, .editCollections(cipher))
        XCTAssertTrue(coordinator.contexts.last as? AddEditItemProcessor === subject)
    }

    /// `receive(_:)` with `.morePressed(.moveToOrganization)` navigates the user to the move to
    /// organization view.
    @MainActor
    func test_receive_morePressed_moveToOrganization() throws {
        let cipher = CipherView.fixture(id: "1")
        subject.state = try XCTUnwrap(
            CipherItemState(
                existing: cipher,
                hasPremium: false
            )
        )

        subject.receive(.morePressed(.moveToOrganization))

        XCTAssertEqual(coordinator.routes.last, .moveToOrganization(cipher))
        XCTAssertTrue(coordinator.contexts.last as? AddEditItemProcessor === subject)
    }

    /// `receive(_:)` with `.nameChanged` with a value updates the state correctly.
    @MainActor
    func test_receive_nameChanged_withValue() {
        subject.state.name = ""
        subject.receive(.nameChanged("name"))

        XCTAssertEqual(subject.state.name, "name")
    }

    /// `receive(_:)` with `.nameChanged` without a value updates the state correctly.
    @MainActor
    func test_receive_nameChanged_withoutValue() {
        subject.state.name = "name"
        subject.receive(.nameChanged(""))

        XCTAssertEqual(subject.state.name, "")
    }

    /// `receive(_:)` with `.newUriPressed` adds a new URI field to the state.
    @MainActor
    func test_receive_newUriPressed() {
        subject.receive(.newUriPressed)

        // TODO: BIT-901 state assertion for added field
    }

    /// `receive(_:)` with `.guidedTourViewAction(.nextTapped)` updates the guided tour state to the next step.
    @MainActor
    func test_receive_nextTapped() {
        subject.state.guidedTourViewState.currentIndex = 0

        subject.receive(.guidedTourViewAction(.nextTapped))
        XCTAssertEqual(subject.state.guidedTourViewState.currentStepState, .loginStep2)
        XCTAssertEqual(subject.state.guidedTourViewState.currentIndex, 1)

        subject.receive(.guidedTourViewAction(.nextTapped))
        XCTAssertEqual(subject.state.guidedTourViewState.currentStepState, .loginStep3)
        XCTAssertEqual(subject.state.guidedTourViewState.currentIndex, 2)
    }

    /// `receive(_:)` with `.notesChanged` with a value updates the state correctly.
    @MainActor
    func test_receive_notesChanged_withValue() {
        subject.state.notes = ""
        subject.receive(.notesChanged("notes"))

        XCTAssertEqual(subject.state.notes, "notes")
    }

    /// `receive(_:)` with `.notesChanged` without a value updates the state correctly.
    @MainActor
    func test_receive_notesChanged_withoutValue() {
        subject.state.notes = "notes"
        subject.receive(.notesChanged(""))

        XCTAssertEqual(subject.state.notes, "")
    }

    /// `receive(_:)` with `.ownerChanged` updates the state correctly.
    @MainActor
    func test_receive_ownerChanged() {
        let personalOwner = CipherOwner.personal(email: "user@bitwarden.com")
        let organizationOwner = CipherOwner.organization(id: "1", name: "Organization")
        subject.state.ownershipOptions = [personalOwner, organizationOwner]

        XCTAssertEqual(subject.state.owner, personalOwner)

        subject.receive(.ownerChanged(organizationOwner))

        XCTAssertEqual(subject.state.owner, organizationOwner)
    }

    /// `receive(_:)` with `.passwordChanged` with a value updates the state correctly.
    @MainActor
    func test_receive_passwordChanged_withValue() {
        subject.state.loginState.password = ""
        subject.receive(.passwordChanged("password"))

        XCTAssertEqual(subject.state.loginState.password, "password")
    }

    /// `receive(_:)` with `.passwordChanged` without a value updates the state correctly.
    @MainActor
    func test_receive_passwordChanged_withoutValue() {
        subject.state.loginState.password = "password"
        subject.receive(.passwordChanged(""))

        XCTAssertEqual(subject.state.loginState.password, "")
    }

    /// `receive(_:)` with `.sshKeyItemAction` and `privateKeyVisibilityPressed` toggles
    /// the visibility of the `privateKey` field.
    @MainActor
    func test_receive_sshKeyItemAction_withoutValue() {
        subject.state.sshKeyState.isPrivateKeyVisible = false
        subject.receive(.sshKeyItemAction(.privateKeyVisibilityPressed))

        XCTAssertTrue(subject.state.sshKeyState.isPrivateKeyVisible)
    }

    /// `receive(_:)` with `.toastShown` without a value updates the state correctly.
    @MainActor
    func test_receive_toastShown_withoutValue() {
        let toast = Toast(title: "123")
        subject.state.toast = toast
        subject.receive(.toastShown(nil))

        XCTAssertEqual(subject.state.toast, nil)
    }

    /// `receive(_:)` with `.toastShown` with a value updates the state correctly.
    @MainActor
    func test_receive_toastShown_withValue() {
        let toast = Toast(title: "123")
        subject.receive(.toastShown(toast))

        XCTAssertEqual(subject.state.toast, toast)
    }

    /// `receive(_:)` with `.toggleAdditionalOptionsExpanded` toggles whether the additional options
    /// are expanded.
    @MainActor
    func test_receive_toggleAdditionalOptionsExpanded() {
        subject.receive(.toggleAdditionalOptionsExpanded(true))
        XCTAssertTrue(subject.state.isAdditionalOptionsExpanded)

        subject.receive(.toggleAdditionalOptionsExpanded(false))
        XCTAssertFalse(subject.state.isAdditionalOptionsExpanded)
    }

    /// `receive(_:)` with `guidedTourViewAction(.toggleGuidedTourVisibilityChanged)`
    /// updates the state correctly.
    @MainActor
    func test_receive_guidedTourViewAction_toggleGuidedTourVisibilityChanged() {
        subject.state.guidedTourViewState.showGuidedTour = false

        subject.receive(.guidedTourViewAction(.toggleGuidedTourVisibilityChanged(true)))
        XCTAssertTrue(subject.state.guidedTourViewState.showGuidedTour)

        subject.receive(.guidedTourViewAction(.toggleGuidedTourVisibilityChanged(false)))
        XCTAssertFalse(subject.state.guidedTourViewState.showGuidedTour)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `true` updates the state correctly.
    @MainActor
    func test_receive_togglePasswordVisibilityChanged_withTrue() {
        subject.state.loginState.isPasswordVisible = false

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.loginState.isPasswordVisible)

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.loginState.isPasswordVisible)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `true` when editing
    ///  sends an event.
    @MainActor
    func test_receive_togglePasswordVisibilityChanged_withTrue_whenEditing() {
        subject = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                cameraService: cameraService,
                errorReporter: errorReporter,
                eventService: eventService,
                httpClient: client,
                pasteboardService: pasteboardService,
                policyService: policyService,
                stateService: stateService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState(
                existing: CipherView.fixture(id: "100"),
                hasPremium: true
            )!
        )
        subject.state.loginState.isPasswordVisible = false

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.loginState.isPasswordVisible)

        waitFor(eventService.collectCipherId != nil)
        XCTAssertEqual(eventService.collectCipherId, "100")
        XCTAssertEqual(eventService.collectEventType, .cipherClientToggledPasswordVisible)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `false` updates the state correctly.
    @MainActor
    func test_receive_togglePasswordVisibilityChanged_withFalse() {
        subject.state.loginState.isPasswordVisible = true

        subject.receive(.togglePasswordVisibilityChanged(false))
        XCTAssertFalse(subject.state.loginState.isPasswordVisible)

        subject.receive(.togglePasswordVisibilityChanged(false))
        XCTAssertFalse(subject.state.loginState.isPasswordVisible)
    }

    /// `receive(_:)` with `.totpFieldLeftFocus` with a key with spaces.
    @MainActor
    func test_receive_totpFieldLeftFocus_validKey_standardState() throws {
        let keyWithSpaces = "pasta batman"
        subject.state.loginState.totpState = LoginTOTPState(keyWithSpaces)
        subject.receive(.totpFieldLeftFocus)

        XCTAssertEqual(
            subject.state.loginState.totpState.authKeyModel?.rawAuthenticatorKey,
            keyWithSpaces
        )
        XCTAssertEqual(
            keyWithSpaces,
            subject.state.loginState.totpState.rawAuthenticatorKeyString
        )
        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertEqual(
            subject.state.loginState.totpState.authKeyModel?.totpKey,
            .standard(key: keyWithSpaces)
        )
    }

    /// `receive(_:)` with `.totpFieldLeftFocus` clears the authenticator key.
    @MainActor
    func test_receive_totpFieldLeftFocus_validKey() {
        subject.state.loginState.totpState = LoginTOTPState(.standardTotpKey)
        subject.receive(.totpFieldLeftFocus)

        XCTAssertTrue(coordinator.alertShown.isEmpty)
        switch subject.state.loginState.totpState {
        case let .key(keyModel):
            XCTAssertEqual(keyModel.rawAuthenticatorKey, .standardTotpKey)
        default:
            XCTFail("Unexpected State")
        }
    }

    /// `receive(_:)` with `.uriChanged` with a valid index updates the state correctly.
    @MainActor
    func test_receive_uriChanged_withValidIndex() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: ""
            ),
        ]
        subject.receive(.uriChanged("uri", index: 0))

        XCTAssertEqual(subject.state.loginState.uris[0].uri, "uri")
    }

    /// `receive(_:)` with `.uriChanged` without a valid index does not update the state.
    @MainActor
    func test_receive_uriChanged_withoutValidIndex() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]
        subject.receive(.uriChanged("new value", index: 5))

        XCTAssertEqual(subject.state.loginState.uris[0].uri, "uri")
    }

    /// `receive(_:)` with `.uriTypeChanged` with a valid id updates the state correctly.
    @MainActor
    func test_receive_uriTypeChanged_withValidUriId() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]
        subject.receive(.uriTypeChanged(.custom(.host), index: 0))

        XCTAssertEqual(subject.state.loginState.uris[0].matchType, .custom(.host))
    }

    /// `receive(_:)` with `.uriTypeChanged` without a valid id does not update the state.
    @MainActor
    func test_receive_uriTypeChanged_withoutValidUriId() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]
        subject.receive(.uriTypeChanged(.custom(.host), index: 5))

        XCTAssertEqual(subject.state.loginState.uris[0].matchType, .default)
    }

    /// `receive(_:)` with `.usernameChanged` without a value updates the state correctly.
    @MainActor
    func test_receive_usernameChanged_withValue() {
        subject.state.loginState.username = ""
        subject.receive(.usernameChanged("username"))

        XCTAssertEqual(subject.state.loginState.username, "username")
    }

    /// `receive(_:)` with `.usernameChanged` without a value updates the state correctly.
    @MainActor
    func test_receive_usernameChanged_withoutValue() {
        subject.state.loginState.username = "username"
        subject.receive(.usernameChanged(""))

        XCTAssertEqual(subject.state.loginState.username, "")
    }

    /// `receive(_:)` with `.cardFieldChanged(.brandChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_cardholderNameChanged_withValidValue() {
        subject.state.cardItemState.brand = .default
        subject.receive(.cardFieldChanged(.brandChanged(.custom(.visa))))
        XCTAssertEqual(subject.state.cardItemState.brand, .custom(.visa))
    }

    /// `receive(_:)` with `.cardFieldChanged(.brandChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_cardholderNameChanged_withoutValidValue() {
        subject.state.cardItemState.brand = .custom(.visa)
        subject.receive(.cardFieldChanged(.brandChanged(.default)))
        XCTAssertEqual(subject.state.cardItemState.brand, .default)
    }

    /// `receive(_:)` with `.cardFieldChanged(.cardholderNameChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_cardholderNameChanged() {
        subject.state.cardItemState.cardholderName = "James"
        subject.receive(.cardFieldChanged(.cardholderNameChanged("Jane")))
        XCTAssertEqual(subject.state.cardItemState.cardholderName, "Jane")
    }

    /// `receive(_:)` with `.cardFieldChanged(.cardNumberChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_cardNumberChanged() {
        subject.state.cardItemState.cardNumber = "123"
        subject.receive(.cardFieldChanged(.cardNumberChanged("12345")))
        XCTAssertEqual(subject.state.cardItemState.cardNumber, "12345")
    }

    /// `receive(_:)` with `.cardFieldChanged(.cardSecurityCodeChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_cardSecurityCodeChanged() {
        subject.state.cardItemState.cardSecurityCode = "123"
        subject.receive(.cardFieldChanged(.cardSecurityCodeChanged("456")))
        XCTAssertEqual(subject.state.cardItemState.cardSecurityCode, "456")
    }

    /// `receive(_:)` with `.cardFieldChanged(.expirationMonthChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_expirationMonthChanged_withValidValue() {
        subject.state.cardItemState.brand = .default
        subject.receive(.cardFieldChanged(.expirationMonthChanged(.custom(.jul))))
        XCTAssertEqual(subject.state.cardItemState.expirationMonth, .custom(.jul))
    }

    /// `receive(_:)` with `.cardFieldChanged(.brandChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_expirationMonthChanged_withoutValidValue() {
        subject.state.cardItemState.expirationMonth = .custom(.jul)
        subject.receive(.cardFieldChanged(.expirationMonthChanged(.default)))
        XCTAssertEqual(subject.state.cardItemState.expirationMonth, .default)
    }

    /// `receive(_:)` with `.cardFieldChanged(.expirationYearChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_expirationYearChanged() {
        subject.state.cardItemState.expirationYear = "2009"
        subject.receive(.cardFieldChanged(.expirationYearChanged("2029")))
        XCTAssertEqual(subject.state.cardItemState.expirationYear, "2029")
    }

    /// `receive(_:)` with `.identityFieldChanged(.titleChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_titleChange_withValidValue() {
        subject.state.identityState.title = .default
        subject.receive(.identityFieldChanged(.titleChanged(.custom(.mr))))
        XCTAssertEqual(subject.state.identityState.title, .custom(.mr))
    }

    /// `receive(_:)` with `.identityFieldChanged(.titleChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_titleChange_withOutValidValue() {
        subject.state.identityState.title = DefaultableType.custom(.mr)
        subject.receive(.identityFieldChanged(.titleChanged(DefaultableType.default)))
        XCTAssertEqual(subject.state.identityState.title, DefaultableType.default)
    }

    /// `receive(_:)` with `.cardFieldChanged(.toggleCodeVisibilityChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_toggleCodeVisibilityChanged() {
        subject.receive(.cardFieldChanged(.toggleCodeVisibilityChanged(true)))
        XCTAssertEqual(subject.state.cardItemState.isCodeVisible, true)
    }

    /// `receive(_:)` with `.cardFieldChanged(.toggleNumberVisibilityChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_cardFieldChanged_toggleNumberVisibilityChanged() {
        subject.receive(.cardFieldChanged(.toggleNumberVisibilityChanged(true)))
        XCTAssertEqual(subject.state.cardItemState.isNumberVisible, true)
    }

    /// `receive(_:)` with `.identityFieldChanged(.firstNameChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_firstNameChange_withValidValue() {
        subject.state.identityState.firstName = ""
        subject.receive(.identityFieldChanged(.firstNameChanged("firstName")))

        XCTAssertEqual(subject.state.identityState.firstName, "firstName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.firstNameChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_firstNameChange_withOutValidValue() {
        subject.state.identityState.firstName = "firstName"
        subject.receive(.identityFieldChanged(.firstNameChanged("")))

        XCTAssertEqual(subject.state.identityState.firstName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.middleNameChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_middleNameChange_withValidValue() {
        subject.state.identityState.middleName = ""
        subject.receive(.identityFieldChanged(.middleNameChanged("middleName")))

        XCTAssertEqual(subject.state.identityState.middleName, "middleName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.middleNameChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_middleNameChange_withOutValidValue() {
        subject.state.identityState.middleName = "middleName"
        subject.receive(.identityFieldChanged(.middleNameChanged("")))

        XCTAssertEqual(subject.state.identityState.middleName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.lastNameChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_lastNameChange_withValidValue() {
        subject.state.identityState.lastName = ""
        subject.receive(.identityFieldChanged(.lastNameChanged("lastName")))

        XCTAssertEqual(subject.state.identityState.lastName, "lastName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.lastNameChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_lastNameChange_withOutValidValue() {
        subject.state.identityState.lastName = "lastName"
        subject.receive(.identityFieldChanged(.lastNameChanged("")))

        XCTAssertEqual(subject.state.identityState.lastName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.userNameChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_userNameChange_withValidValue() {
        subject.state.identityState.userName = ""
        subject.receive(.identityFieldChanged(.userNameChanged("userName")))

        XCTAssertEqual(subject.state.identityState.userName, "userName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.userNameChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_userNameChange_withOutValidValue() {
        subject.state.identityState.userName = "userName"
        subject.receive(.identityFieldChanged(.userNameChanged("")))

        XCTAssertEqual(subject.state.identityState.userName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.companyChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_companyChange_withValidValue() {
        subject.state.identityState.company = ""
        subject.receive(.identityFieldChanged(.companyChanged("company")))

        XCTAssertEqual(subject.state.identityState.company, "company")
    }

    /// `receive(_:)` with `.identityFieldChanged(.companyChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_companyChange_withOutValidValue() {
        subject.state.identityState.company = "company"
        subject.receive(.identityFieldChanged(.companyChanged("")))

        XCTAssertEqual(subject.state.identityState.company, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.passportNumberChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_passportNumberChange_withValidValue() {
        subject.state.identityState.passportNumber = ""
        subject.receive(.identityFieldChanged(.passportNumberChanged("passportNumber")))

        XCTAssertEqual(subject.state.identityState.passportNumber, "passportNumber")
    }

    /// `receive(_:)` with `.identityFieldChanged(.passportNumberChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_passportNumberChange_withOutValidValue() {
        subject.state.identityState.passportNumber = "passportNumber"
        subject.receive(.identityFieldChanged(.passportNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.passportNumber, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.socialSecurityNumberChanged)`
    /// with a value updates the state correctly.
    @MainActor
    func test_receive_identity_socialSecurityNumberChange_withValidValue() {
        subject.state.identityState.socialSecurityNumber = ""
        subject.receive(.identityFieldChanged(.socialSecurityNumberChanged("socialSecurityNumber")))

        XCTAssertEqual(subject.state.identityState.socialSecurityNumber, "socialSecurityNumber")
    }

    /// `receive(_:)` with `.identityFieldChanged(.passportNumberChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_socialSecurityNumberChange_withOutValidValue() {
        subject.state.identityState.passportNumber = "socialSecurityNumber"
        subject.receive(.identityFieldChanged(.socialSecurityNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.socialSecurityNumber, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.licenseNumberChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_licenseNumberChange_withValidValue() {
        subject.state.identityState.licenseNumber = ""
        subject.receive(.identityFieldChanged(.licenseNumberChanged("licenseNumber")))

        XCTAssertEqual(subject.state.identityState.licenseNumber, "licenseNumber")
    }

    /// `receive(_:)` with `.identityFieldChanged(.licenseNumberChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_licenseNumberChange_withOutValidValue() {
        subject.state.identityState.licenseNumber = "licenseNumber"
        subject.receive(.identityFieldChanged(.licenseNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.licenseNumber, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.emailChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_emailChange_withValidValue() {
        subject.state.identityState.email = ""
        subject.receive(.identityFieldChanged(.emailChanged("email")))

        XCTAssertEqual(subject.state.identityState.email, "email")
    }

    /// `receive(_:)` with `.identityFieldChanged(.emailChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_emailChange_withOutValidValue() {
        subject.state.identityState.email = "email"
        subject.receive(.identityFieldChanged(.emailChanged("")))

        XCTAssertEqual(subject.state.identityState.email, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.phoneNumberChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_phoneChange_withValidValue() {
        subject.state.identityState.phone = ""
        subject.receive(.identityFieldChanged(.phoneNumberChanged("phone")))

        XCTAssertEqual(subject.state.identityState.phone, "phone")
    }

    /// `receive(_:)` with `.identityFieldChanged(.phoneNumberChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_phoneChange_withOutValidValue() {
        subject.state.identityState.phone = "phone"
        subject.receive(.identityFieldChanged(.phoneNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.phone, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address1Changed)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_address1Change_withValidValue() {
        subject.state.identityState.address1 = ""
        subject.receive(.identityFieldChanged(.address1Changed("address1")))

        XCTAssertEqual(subject.state.identityState.address1, "address1")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address1Changed)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_address1Change_withOutValidValue() {
        subject.state.identityState.address1 = "address1"
        subject.receive(.identityFieldChanged(.address1Changed("")))

        XCTAssertEqual(subject.state.identityState.address1, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address2Changed)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_address2Change_withValidValue() {
        subject.state.identityState.address2 = ""
        subject.receive(.identityFieldChanged(.address2Changed("address2")))

        XCTAssertEqual(subject.state.identityState.address2, "address2")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address2Changed)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_address2Change_withOutValidValue() {
        subject.state.identityState.address2 = "address2"
        subject.receive(.identityFieldChanged(.address2Changed("")))

        XCTAssertEqual(subject.state.identityState.address2, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address3Changed)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_address3Change_withValidValue() {
        subject.state.identityState.address3 = ""
        subject.receive(.identityFieldChanged(.address3Changed("address3")))

        XCTAssertEqual(subject.state.identityState.address3, "address3")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address3Changed)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_address3Change_withOutValidValue() {
        subject.state.identityState.address3 = "address3"
        subject.receive(.identityFieldChanged(.address3Changed("")))

        XCTAssertEqual(subject.state.identityState.address3, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.cityOrTownChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_cityOrTownChange_withValidValue() {
        subject.state.identityState.cityOrTown = ""
        subject.receive(.identityFieldChanged(.cityOrTownChanged("cityOrTown")))

        XCTAssertEqual(subject.state.identityState.cityOrTown, "cityOrTown")
    }

    /// `receive(_:)` with `.identityFieldChanged(.cityOrTownChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_cityOrTownChange_withOutValidValue() {
        subject.state.identityState.cityOrTown = "cityOrTown"
        subject.receive(.identityFieldChanged(.cityOrTownChanged("")))

        XCTAssertEqual(subject.state.identityState.cityOrTown, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.stateChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_stateChange_withValidValue() {
        subject.state.identityState.state = ""
        subject.receive(.identityFieldChanged(.stateChanged("state")))

        XCTAssertEqual(subject.state.identityState.state, "state")
    }

    /// `receive(_:)` with `.identityFieldChanged(.stateChanged)` without
    ///  a value updates the state correctly.
    @MainActor
    func test_receive_identity_stateChange_withOutValidValue() {
        subject.state.identityState.state = "state"
        subject.receive(.identityFieldChanged(.stateChanged("")))

        XCTAssertEqual(subject.state.identityState.state, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.postalCodeChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_postalCodeChange_withValidValue() {
        subject.state.identityState.state = ""
        subject.receive(.identityFieldChanged(.postalCodeChanged("55408")))

        XCTAssertEqual(subject.state.identityState.postalCode, "55408")
    }

    /// `receive(_:)` with `.identityFieldChanged(.postalCodeChanged)` without
    ///  a value updates the state correctly.
    @MainActor
    func test_receive_identity_postalCodeChange_withOutValidValue() {
        subject.state.identityState.postalCode = "55408"
        subject.receive(.identityFieldChanged(.postalCodeChanged("")))

        XCTAssertEqual(subject.state.identityState.postalCode, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.countryChanged)` with a value updates the state correctly.
    @MainActor
    func test_receive_identity_countryChange_withValidValue() {
        subject.state.identityState.country = ""
        subject.receive(.identityFieldChanged(.countryChanged("country")))

        XCTAssertEqual(subject.state.identityState.country, "country")
    }

    /// `receive(_:)` with `.identityFieldChanged(.countryChanged)` without a value updates the state correctly.
    @MainActor
    func test_receive_identity_countryChange_withOutValidValue() {
        subject.state.identityState.country = "country"
        subject.receive(.identityFieldChanged(.countryChanged("")))

        XCTAssertEqual(subject.state.identityState.country, "")
    }

    /// `getter:rehydrationState` returns the proper state with the cipher id.
    @MainActor
    func test_rehydrationState() {
        subject.state = CipherItemState(existing: .fixture(id: "1"), hasPremium: false)!
        XCTAssertEqual(subject.rehydrationState?.target, .editCipher(cipherId: "1"))
    }

    /// `getter:rehydrationState` returns the proper state with the cipher id.
    @MainActor
    func test_rehydrationState_nil() {
        subject.state = CipherItemState(addItem: .login, hasPremium: false)
        XCTAssertNil(subject.rehydrationState?.target)
    }
}

// MARK: MockCipherItemOperationDelegate

class MockCipherItemOperationDelegate: CipherItemOperationDelegate {
    var itemAddedCalled = false
    var itemAddedShouldDismiss = true
    var itemDeletedCalled = false
    var itemRestoredCalled = false
    var itemSoftDeletedCalled = false
    var itemUpdatedCalled = false
    var itemUpdatedShouldDismiss = true

    func itemAdded() -> Bool {
        itemAddedCalled = true
        return itemAddedShouldDismiss
    }

    func itemDeleted() {
        itemDeletedCalled = true
    }

    func itemRestored() {
        itemRestoredCalled = true
    }

    func itemSoftDeleted() {
        itemSoftDeletedCalled = true
    }

    func itemUpdated() -> Bool {
        itemUpdatedCalled = true
        return itemUpdatedShouldDismiss
    }
}
