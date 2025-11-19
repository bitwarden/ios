// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AddEditItemViewTests

class AddEditItemViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var processor: MockProcessor<AddEditItemState, AddEditItemAction, AddEditItemEffect>!
    var subject: AddEditItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: CipherItemState(
                hasPremium: true,
            ),
        )
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]
        let store = Store(processor: processor)
        subject = AddEditItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add website button dispatches the `.newUriPressed` action.
    @MainActor
    func test_addWebsiteButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addWebsite)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .newUriPressed)
    }

    /// Tapping the cancel button dispatches the `.dismissPressed` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the check password button performs the `.checkPassword` effect.
    @MainActor
    func test_checkPasswordButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.checkPasswordForDataBreaches)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .checkPasswordPressed)
    }

    /// Tapping the copy totp button performs the `.copyTotp` effect.
    @MainActor
    func test_copyTotpButton_tap() async throws {
        processor.state.loginState.totpState = LoginTOTPState("JBSWY3DPEHPK3PXP")

        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.copyTotp)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .copyTotpPressed)
    }

    /// Tapping the remove passkey button dispatches the `.removePasskeyPressed` action.
    @MainActor
    func test_removePasskeyButton_tap() throws {
        processor.state.loginState.fido2Credentials = [
            .fixture(creationDate: Date(timeIntervalSince1970: 1_710_494_110)),
        ]

        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.removePasskey,
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .removePasskeyPressed)
    }

    /// Tapping the dismiss button in the learn new login  action card sends the
    /// `.dismissNewLoginActionCard` effect.
    @MainActor
    func test_learnNewLoginActionCard_visible_tapDismiss() async throws {
        processor.state = CipherItemState(
            hasPremium: true,
        )
        processor.state.isLearnNewLoginActionCardEligible = true
        let actionCard = try subject.inspect().find(actionCard: Localizations.learnAboutNewLogins)

        let button = try actionCard.find(asyncButton: Localizations.dismiss)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.dismissNewLoginActionCard])
    }

    /// Tapping the 'Get started' button in the learn new login  action card sends the
    /// `.showLearnNewLoginGuidedTour` effect.
    @MainActor
    func test_learnNewLoginActionCard_visible_tapGetStarted() async throws {
        processor.state = CipherItemState(
            hasPremium: true,
        )
        processor.state.isLearnNewLoginActionCardEligible = true
        let actionCard = try subject.inspect().find(actionCard: Localizations.learnAboutNewLogins)

        let button = try actionCard.find(asyncButton: Localizations.getStarted)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.showLearnNewLoginGuidedTour])
    }

    /// Tapping the dismiss button dispatches the `.dismissPressed` action.
    @MainActor
    func test_dismissButton_tap() throws {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true,
        )!
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the favorite button dispatches the `.favoriteChanged(_:)` action.
    @MainActor
    func test_favoriteButton_tap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.favorite)

        processor.state.isFavoriteOn = false
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .favoriteChanged(true))

        processor.state.isFavoriteOn = true
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .favoriteChanged(false))
    }

    /// Updating the folder text field dispatches the `.folderChanged()` action.
    @MainActor
    func test_folderTextField_updateValue() throws {
        let folder = FolderView.fixture(name: "Folder")
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.folder)
        try menuField.select(newValue: DefaultableType<FolderView>.custom(folder))
        XCTAssertEqual(processor.dispatchedActions.last, .folderChanged(.custom(folder)))
    }

    /// Tapping the generate password button dispatches the `.generatePasswordPressed` action.
    @MainActor
    func test_generatePasswordButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generatePassword,
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }

    /// Tapping the generate username button dispatches the `.generateUsernamePressed` action.
    @MainActor
    func test_generateUsernameButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generateUsername,
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generateUsernamePressed)
    }

    /// Tapping the master password re-prompt toggle dispatches the `.masterPasswordRePromptChanged(_:)` action.
    @MainActor
    func test_masterPasswordRePromptToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        processor.state.isMasterPasswordRePromptOn = false
        let toggle = try subject.inspect().find(ViewType.Toggle.self, containing: Localizations.passwordPrompt)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordRePromptChanged(true))
    }

    /// Updating the name text field dispatches the `.nameChanged()` action.
    @MainActor
    func test_nameTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.itemNameRequired)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .nameChanged("text"))
    }

    /// Tapping the new custom field button dispatches the `.newCustomFieldPressed` action.
    @MainActor
    func test_newCustomFieldButton_tap() throws {
        processor.state.isAdditionalOptionsExpanded = true
        let button = try subject.inspect().find(button: Localizations.newCustomField)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .customField(.newCustomFieldPressed))
    }

    /// Tapping the new folder button dispatches the `.addFolder` action.
    @MainActor
    func test_newFolder_tap() throws {
        let button = try subject.inspect().find(button: Localizations.newFolder)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addFolder)
    }

    /// Updating the notes text field dispatches the `.notesChanged()` action.
    @MainActor
    func test_notesTextField_updateValue() throws {
        processor.state.isAdditionalOptionsExpanded = true
        let textField = try subject.inspect().find(
            type: BitwardenUITextViewType.self,
            accessibilityLabel: Localizations.notes,
        )
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .notesChanged("text"))
    }

    /// Updating the owner menu dispatches the `.ownerChanged()` action.
    @MainActor
    func test_ownerTextField_updateValue() throws {
        let organizationOwner = CipherOwner.organization(id: "1", name: "Bitwarden Organization")
        processor.state.ownershipOptions = [
            CipherOwner.personal(email: "user@bitwarden.com"),
            organizationOwner,
        ]
        let menu = try subject.inspect().find(bitwardenMenuField: Localizations.owner)
        try menu.select(newValue: organizationOwner)
        XCTAssertEqual(processor.dispatchedActions.last, .ownerChanged(organizationOwner))
    }

    /// Updating the password text field dispatches the `.passwordChanged()` action.
    @MainActor
    func test_passwordTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.password)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .passwordChanged("text"))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    @MainActor
    func test_passwordVisibilityButton_tap_withPasswordNotVisible() throws {
        processor.state.loginState.isPasswordVisible = false
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibilityChanged(true))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    @MainActor
    func test_passwordVisibilityButton_tap_withPasswordVisible() throws {
        processor.state.loginState.isPasswordVisible = true
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibilityChanged(false))
    }

    /// Tapping the save button performs the `.savePressed` effect when adding a new cipher.
    @MainActor
    func test_saveButton_tapAdd() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    /// Tapping the save button performs the `.savePressed` effect when editing an existing cipher.
    @MainActor
    func test_saveButton_tapEdit() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        processor.state = CipherItemState(existing: .fixture(), hasPremium: false)!
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    /// Tapping the set up authenticator key button dispatches the `.setupTotpPressed` action.
    @MainActor
    func test_setupTotpButton_noKey_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.setUpAuthenticatorKey)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .setupTotpPressed)
    }

    /// Tapping the set up authenticator button dispatches the `.setupTotpPressed` action.
    @MainActor
    func test_setupTotpButton_withKey_tap() async throws {
        processor.state.loginState.totpState = LoginTOTPState("JBSWY3DPEHPK3PXP")

        let button = try subject.inspect().find(asyncButton: Localizations.setUpAuthenticatorKey)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .setupTotpPressed)
    }

    /// Selecting a new value with the uri match type picker dispatches the `.uriTypeChanged` action.
    /// is selected.
    @MainActor
    func test_uriMatchTypePicker_select() throws {
        processor.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri",
            ),
        ]

        let picker = try subject.inspect().find(picker: Localizations.matchDetection)
        try picker.select(value: DefaultableType<BitwardenShared.UriMatchType>.custom(.host))
        XCTAssertEqual(processor.dispatchedActions.last, .uriTypeChanged(.custom(.host), index: 0))
    }

    /// Tapping the uri remove button dispatches the `.removeUriPressed` action.
    @MainActor
    func test_uriRemoveButton_tap() throws {
        processor.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri",
            ),
        ]

        let button = try subject.inspect().find(button: Localizations.remove)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .removeUriPressed(index: 0))
    }

    /// Updating the uri text field dispatches the `.uriChanged()` action.
    @MainActor
    func test_uriTextField_updateValue() throws {
        processor.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri",
            ),
        ]

        let textField = try subject.inspect().find(bitwardenTextField: Localizations.websiteURI)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .uriChanged("text", index: 0))
    }

    /// Updating the name text field dispatches the `.usernameChanged()` action.
    @MainActor
    func test_usernameTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.username)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .usernameChanged("text"))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.userNameChanged())` action.
    @MainActor
    func test_identity_titleMenu_updateValue() throws {
        processor.state.type = .identity
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.title)
        try menuField.select(newValue: DefaultableType.custom(TitleType.ms))
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.titleChanged(.custom(.ms))))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.firstNameChanged())` action.
    @MainActor
    func test_firstNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.firstName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.firstNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.lastNameChanged())` action.
    @MainActor
    func test_lastNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.lastName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.lastNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.middleNameChanged())` action.
    @MainActor
    func test_middleNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.middleName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.middleNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.userNameChanged())` action.
    @MainActor
    func test_identity_userNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.username)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.userNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.companyChanged())` action.
    @MainActor
    func test_companyTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.company)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.companyChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.socialSecurityNumberChanged())` action.
    @MainActor
    func test_socialSecurityNumberTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.ssn)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.socialSecurityNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.passportNumberChanged())` action.
    @MainActor
    func test_passportNumberTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.passportNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.passportNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.licenseNumberChanged())` action.
    @MainActor
    func test_licenseNumberTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.licenseNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.licenseNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.emailChanged())` action.
    @MainActor
    func test_emailTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.email)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.emailChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.phoneNumberChanged())` action.
    @MainActor
    func test_phoneTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.phone)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.phoneNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.address1Changed())` action.
    @MainActor
    func test_address1TextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.address1)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.address1Changed("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.address2Changed())` action.
    @MainActor
    func test_address2TextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.address2)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.address2Changed("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.address3Changed())` action.
    @MainActor
    func test_address3TextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.address3)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.address3Changed("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.cityOrTownChanged())` action.
    @MainActor
    func test_cityOrTownTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.cityTown)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.cityOrTownChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.stateChanged())` action.
    @MainActor
    func test_stateTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.stateProvince)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.stateChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.postalCodeChanged())` action.
    @MainActor
    func test_postalCodeTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.zipPostalCode)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.postalCodeChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.countryChanged())` action.
    @MainActor
    func test_countryTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.country)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.countryChanged("text")))
    }

    // MARK: Private

    /// Creates a `CipherItemState` for an SSH key item.
    /// - Parameters:
    ///   - canViewPrivateKey: Whether the private key can be viewed.
    ///   - isPrivateKeyVisible: Whether the private key is visible.
    /// - Returns: The `CipherItemState` for SSH key item.
    private func sshKeyCipherItemState(canViewPrivateKey: Bool, isPrivateKeyVisible: Bool) -> CipherItemState {
        var state = CipherItemState(
            existing: .fixture(
                id: "fake-id",
            ),
            hasPremium: true,
        )!
        state.name = "Example"
        state.type = .sshKey
        state.sshKeyState = SSHKeyItemState(
            canViewPrivateKey: canViewPrivateKey,
            isPrivateKeyVisible: isPrivateKeyVisible,
            privateKey: "ajsdfopij1ZXCVZXC12312QW",
            publicKey: "ssh-ed25519 AAAAA/asdjfoiwejrpo23323j23ASdfas",
            keyFingerprint: "SHA-256:2qwer233ADJOIq1adfweqe21321qw",
        )
        return state
    }
} // swiftlint:disable:this file_length
