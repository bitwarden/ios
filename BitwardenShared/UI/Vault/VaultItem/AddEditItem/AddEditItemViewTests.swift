import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
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
        processor = MockProcessor(state: CipherItemState())
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

    /// Tapping the cancel button dispatches the `.dismissPressed` action.
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the check password button performs the `.checkPassword` effect.
    func test_checkPasswordButton_tap() async throws {
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.checkPassword)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .checkPasswordPressed)
    }

    /// Tapping the copy totp button performs the `.copyTotp` effect.
    func test_copyTotpButton_tap() async throws {
        processor.state.loginState.totpKey = .init(authenticatorKey: "JBSWY3DPEHPK3PXP")
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.copyTotp)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .copyTotpPressed)
    }

    /// Tapping the dismiss button dispatches the `.dismissPressed` action.
    func test_dismissButton_tap() throws {
        processor.state = CipherItemState(existing: CipherView.loginFixture())!
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the favorite toggle dispatches the `.favoriteChanged(_:)` action.
    func test_favoriteToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        processor.state.isFavoriteOn = false
        let toggle = try subject.inspect().find(ViewType.Toggle.self, containing: Localizations.favorite)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .favoriteChanged(true))
    }

    /// Updating the folder text field dispatches the `.folderChanged()` action.
    func test_folderTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.folder)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .folderChanged("text"))
    }

    /// Tapping the generate password button dispatches the `.generatePasswordPressed` action.
    func test_generatePasswordButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generatePassword
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }

    /// Tapping the generate username button dispatches the `.generateUsernamePressed` action.
    func test_generateUsernameButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generateUsername
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generateUsernamePressed)
    }

    /// Tapping the master password re-prompt toggle dispatches the `.masterPasswordRePromptChanged(_:)` action.
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
    func test_nameTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.name)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .nameChanged("text"))
    }

    /// Tapping the new custom field button dispatches the `.newCustomFieldPressed` action.
    func test_newCustomFieldButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.newCustomField)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .newCustomFieldPressed)
    }

    /// Tapping the new uri button dispatches the `.newUriPressed` action.
    func test_newUriButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.newUri)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .newUriPressed)
    }

    /// Updating the notes text field dispatches the `.notesChanged()` action.
    func test_notesTextField_updateValue() throws {
        let textField = try subject.inspect().find(
            bitwardenTextFieldWithAccessibilityLabel: Localizations.notes
        )
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .notesChanged("text"))
    }

    /// Updating the owner menu dispatches the `.ownerChanged()` action.
    func test_ownerTextField_updateValue() throws {
        let organizationOwner = CipherOwner.organization(id: "1", name: "Bitwarden Organization")
        processor.state.ownershipOptions = [
            CipherOwner.personal(email: "user@bitwarden.com"),
            organizationOwner,
        ]
        let menu = try subject.inspect().find(bitwardenMenuField: Localizations.whoOwnsThisItem)
        try menu.select(newValue: organizationOwner)
        XCTAssertEqual(processor.dispatchedActions.last, .ownerChanged(organizationOwner))
    }

    /// Updating the password text field dispatches the `.passwordChanged()` action.
    func test_passwordTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.password)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .passwordChanged("text"))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    func test_passwordVisibilityButton_tap_withPasswordNotVisible() throws {
        processor.state.loginState.isPasswordVisible = false
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibilityChanged(true))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    func test_passwordVisibilityButton_tap_withPasswordVisible() throws {
        processor.state.loginState.isPasswordVisible = true
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibilityChanged(false))
    }

    /// Tapping the save button performs the `.savePressed` effect.
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    /// Tapping the setup totp button disptaches the `.setupTotpPressed` action.
    func test_setupTotpButton_noKey_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.setupTotp)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .setupTotpPressed)
    }

    /// Tapping the setup totp button disptaches the `.setupTotpPressed` action.
    func test_setupTotpButton_withKey_tap() async throws {
        processor.state.loginState.totpKey = .init(authenticatorKey: "JBSWY3DPEHPK3PXP")
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.setupTotp)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .setupTotpPressed)
    }

    func test_typeMenuField_updateValue() throws {
        processor.state.type = .login
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.type)
        try menuField.select(newValue: BitwardenShared.CipherType.card)
        XCTAssertEqual(processor.dispatchedActions.last, .typeChanged(.card))
    }

    /// Selecting a new value with the uri match type picker dispatches the `.uriTypeChanged` action.
    /// is selected.
    func test_uriMatchTypePicker_select() throws {
        processor.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]

        let picker = try subject.inspect().find(picker: Localizations.matchDetection)
        try picker.select(value: DefaultableType<BitwardenShared.UriMatchType>.custom(.host))
        XCTAssertEqual(processor.dispatchedActions.last, .uriTypeChanged(.custom(.host), index: 0))
    }

    /// Tapping the uri remove button dispatches the `.removeUriPressed` action.
    func test_uriRemoveButton_tap() throws {
        processor.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]

        let button = try subject.inspect().find(button: Localizations.remove)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .removeUriPressed(index: 0))
    }

    /// Updating the uri text field dispatches the `.uriChanged()` action.
    func test_uriTextField_updateValue() throws {
        processor.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]

        let textField = try subject.inspect().find(bitwardenTextField: Localizations.uri)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .uriChanged("text", index: 0))
    }

    /// Updating the name text field dispatches the `.usernameChanged()` action.
    func test_usernameTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.username)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .usernameChanged("text"))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.userNameChanged())` action.
    func test_identity_titleMenu_updateValue() throws {
        processor.state.type = .identity
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.title)
        try menuField.select(newValue: DefaultableType.custom(TitleType.ms))
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.titleChanged(.custom(.ms))))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.firstNameChanged())` action.
    func test_firstNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.firstName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.firstNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.lastNameChanged())` action.
    func test_lastNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.lastName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.lastNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.middleNameChanged())` action.
    func test_middleNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.middleName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.middleNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.userNameChanged())` action.
    func test_identity_userNameTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.username)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.userNameChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.companyChanged())` action.
    func test_companyTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.company)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.companyChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.socialSecurityNumberChanged())` action.
    func test_socialSecurityNumberTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.ssn)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.socialSecurityNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.passportNumberChanged())` action.
    func test_passportNumberTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.passportNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.passportNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.licenseNumberChanged())` action.
    func test_licenseNumberTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.licenseNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.licenseNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.emailChanged())` action.
    func test_emailTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.email)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.emailChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.phoneNumberChanged())` action.
    func test_phoneTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.phone)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.phoneNumberChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.address1Changed())` action.
    func test_address1TextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.address1)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.address1Changed("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.address2Changed())` action.
    func test_address2TextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.address2)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.address2Changed("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.address3Changed())` action.
    func test_address3TextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.address3)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.address3Changed("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.cityOrTownChanged())` action.
    func test_cityOrTownTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.cityTown)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.cityOrTownChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.stateChanged())` action.
    func test_stateTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.stateProvince)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.stateChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.postalCodeChanged())` action.
    func test_postalCodeTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.zipPostalCode)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.postalCodeChanged("text")))
    }

    /// Updating the name text field dispatches the `.identityFieldChanged(.countryChanged())` action.
    func test_countryTextField_updateValue() throws {
        processor.state.type = .identity
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.country)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .identityFieldChanged(.countryChanged("text")))
    }

    // MARK: Snapshots

    func test_snapshot_add_empty() {
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    /// Tests the add state with identity item empty.
    func test_snapshot_add_identity_full_fieldsEmpty() {
        processor.state.type = .identity
        processor.state.name = ""
        processor.state.identityState = .init()
        processor.state.isFavoriteOn = false
        processor.state.isMasterPasswordRePromptOn = false
        processor.state.notes = ""
        processor.state.folder = ""

        assertSnapshot(of: subject, as: .tallPortrait2)
    }

    /// Tests the add state with identity item filled.
    func test_snapshot_add_identity_full_fieldsFilled() {
        processor.state.type = .identity
        processor.state.name = "my identity"
        processor.state.identityState = .fixture(
            title: .custom(.dr),
            firstName: "First",
            lastName: "Last",
            middleName: "Middle",
            userName: "userName",
            company: "Company name",
            socialSecurityNumber: "12-345-6789",
            passportNumber: "passport #",
            licenseNumber: "license #",
            email: "hello@email.com",
            phone: "(123) 456-7890",
            address1: "123 street",
            address2: "address2",
            address3: "address3",
            cityOrTown: "City",
            state: "State",
            postalCode: "1234",
            country: "country"
        )
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait2)
    }

    /// Tests the add state with identity item filled with large text.
    func test_snapshot_add_identity_full_fieldsFilled_largeText() {
        processor.state.type = .identity
        processor.state.name = "my identity"
        processor.state.identityState = .fixture(
            title: .custom(.dr),
            firstName: "First",
            lastName: "Last",
            middleName: "Middle",
            userName: "userName",
            company: "Company name",
            socialSecurityNumber: "12-345-6789",
            passportNumber: "passport #",
            licenseNumber: "license #",
            email: "hello@email.com",
            phone: "(123) 456-7890",
            address1: "123 street",
            address2: "address2",
            address3: "address3",
            cityOrTown: "City",
            state: "State",
            postalCode: "1234",
            country: "country"
        )
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 7))
    }

    /// Tests the add state with the password field not visible.
    func test_snapshot_add_login_full_fieldsNotVisible() {
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.loginState = .fixture(
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username"
        )
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.loginState.uris = [
            UriState(id: "id", matchType: .default, uri: URL.example.absoluteString),
        ]
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    /// Tests the add state with all fields.
    func test_snapshot_add_login_full_fieldsVisible() {
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.loginState.username = "username"
        processor.state.loginState.password = "password1!"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.loginState.uris = [
            UriState(id: "id", matchType: .default, uri: URL.example.absoluteString),
        ]
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        processor.state.loginState.isPasswordVisible = true

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_add_login_collections() {
        processor.state.collections = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]
        processor.state.ownershipOptions.append(.organization(id: "1", name: "Organization"))
        processor.state.owner = .organization(id: "1", name: "Organization")
        processor.state.collectionIds = ["2"]

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_add_login_collectionsNone() {
        processor.state.ownershipOptions.append(.organization(id: "1", name: "Organization"))
        processor.state.owner = .organization(id: "1", name: "Organization")

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_edit_full_fieldsNotVisible() {
        processor.state = CipherItemState(existing: CipherView.loginFixture())!
        processor.state.loginState = .fixture(
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username"
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_add_secureNote_full_fieldsVisible() {
        processor.state.type = .secureNote
        processor.state.name = "Secure Note Name"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_edit_full_disabledViewPassword() {
        processor.state = CipherItemState(existing: CipherView.loginFixture())!
        processor.state.loginState = .fixture(
            canViewPassword: false,
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username"
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_edit_full_fieldsNotVisible_largeText() {
        processor.state = CipherItemState(existing: CipherView.loginFixture())!
        processor.state.loginState = .fixture(
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username"
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject, as: .tallPortraitAX5())
    }

    func test_snapshot_edit_full_fieldsVisible() {
        processor.state = CipherItemState(existing: CipherView.loginFixture())!
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.loginState = .fixture(
            isPasswordVisible: true,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username"
        )
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_edit_full_fieldsVisible_largeText() {
        processor.state = CipherItemState(existing: CipherView.loginFixture())!
        processor.state.loginState = .fixture(
            isPasswordVisible: true,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username"
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject, as: .tallPortraitAX5())
    }

    /// Test a snapshot of the AddEditView previews.
    func test_snapshot_previews_addEditItemView() {
        for preview in AddEditItemView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [
                    .tallPortrait,
                    .tallPortraitAX5(heightMultiple: 5),
                    .defaultPortraitDark,
                ]
            )
        }
    }
} // swiftlint:disable:this file_length
