@preconcurrency import BitwardenSdk
import Foundation
import UIKit

// MARK: - CipherItemOperationDelegate

/// An object that is notified when specific circumstances in the add/edit/delete item view have occurred.
///
@MainActor
protocol CipherItemOperationDelegate: AnyObject {
    /// Called when a new cipher item has been successfully added.
    ///
    /// - Returns: A boolean indicating whether the view should be dismissed. Defaults to `true`.
    ///     If `false` is returned the delegate is responsible for dismissing the view.
    ///
    func itemAdded() -> Bool

    /// Called when the cipher item has been successfully permanently deleted.
    func itemDeleted()

    /// Called when the cipher item has been successfully restored.
    func itemRestored()

    /// Called when the cipher item has been successfully soft deleted.
    func itemSoftDeleted()

    /// Called when a cipher item has been successfully updated.
    ///
    /// - Returns: A boolean indicating whether the view should be dismissed. Defaults to `true`.
    ///     If `false` is returned the delegate is responsible for dismissing the view.
    ///
    func itemUpdated() -> Bool
}

extension CipherItemOperationDelegate {
    func itemAdded() -> Bool { true }

    func itemDeleted() {}

    func itemRestored() {}

    func itemSoftDeleted() {}

    func itemUpdated() -> Bool { true }
}

// MARK: - AddEditItemProcessor

/// The processor used to manage state and handle actions for the add item screen.
final class AddEditItemProcessor: StateProcessor<// swiftlint:disable:this type_body_length
    AddEditItemState,
    AddEditItemAction,
    AddEditItemEffect
>, Rehydratable {
    // MARK: Types

    typealias Services = HasAPIService
        & HasAuthRepository
        & HasCameraService
        & HasConfigService
        & HasErrorReporter
        & HasEventService
        & HasFido2UserInterfaceHelper
        & HasPasteboardService
        & HasPolicyService
        & HasRehydrationHelper
        & HasReviewPromptService
        & HasSettingsRepository
        & HasStateService
        & HasTOTPService
        & HasVaultRepository

    // MARK: Public properties

    var rehydrationState: RehydrationState? {
        guard let id = state.cipher.id else { return nil }
        return RehydrationState(target: .editCipher(cipherId: id))
    }

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The delegate that is notified when delete cipher item have occurred.
    private weak var delegate: CipherItemOperationDelegate?

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AddEditItemProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - delegate: The delegate that is notified when add/edit/delete cipher item have occurred.
    ///   - services: The services required by this processor.
    ///   - state: The initial state for the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        delegate: CipherItemOperationDelegate?,
        services: Services,
        state: AddEditItemState
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)

        if !state.configuration.isAdding {
            Task {
                await self.services.rehydrationHelper.addRehydratableTarget(self)
            }
        }
    }

    // MARK: Methods

    override func perform(_ effect: AddEditItemEffect) async {
        switch effect {
        case .appeared:
            await showPasswordAutofillAlertIfNeeded()
            await checkIfUserHasMasterPassword()
            await checkLearnNewLoginActionCardEligibility()
        case .checkPasswordPressed:
            await checkPassword()
        case .copyTotpPressed:
            services.pasteboardService.copy(state.loginState.authenticatorKey)
            state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.authenticatorKey))
        case .dismissNewLoginActionCard:
            state.isLearnNewLoginActionCardEligible = false
            await services.stateService.setLearnNewLoginActionCardStatus(.complete)
        case .fetchCipherOptions:
            await fetchCipherOptions()
        case .savePressed:
            await saveItem()
        case .setupTotpPressed:
            await setupTotp()
        case .deletePressed:
            await showSoftDeleteConfirmation()
        case .showLearnNewLoginGuidedTour:
            state.isLearnNewLoginActionCardEligible = false
            await services.stateService.setLearnNewLoginActionCardStatus(.complete)
            state.guidedTourViewState.currentIndex = 0
            state.guidedTourViewState.showGuidedTour = true
        case .streamFolders:
            await streamFolders()
        }
    }

    override func receive(_ action: AddEditItemAction) { // swiftlint:disable:this function_body_length
        switch action {
        case .addFolder:
            coordinator.navigate(to: .addFolder, context: self)
        case let .authKeyVisibilityTapped(newValue):
            state.loginState.isAuthKeyVisible = newValue
        case let .cardFieldChanged(cardFieldAction):
            updateCardState(&state, for: cardFieldAction)
        case let .collectionToggleChanged(newValue, collectionId):
            state.toggleCollection(newValue: newValue, collectionId: collectionId)
        case let .customField(action):
            handleCustomFieldAction(action)
        case .dismissPressed:
            handleDismiss()
        case let .favoriteChanged(newValue):
            state.isFavoriteOn = newValue
        case let .folderChanged(newValue):
            state.folder = newValue
        case .generatePasswordPressed:
            if state.loginState.password.isEmpty {
                coordinator.navigate(to: .generator(.password), context: self)
            } else {
                presentReplacementAlert(for: .password)
            }
        case .generateUsernamePressed:
            if state.loginState.username.isEmpty {
                let emailWebsite = state.loginState.generatorEmailWebsite
                coordinator.navigate(to: .generator(.username, emailWebsite: emailWebsite), context: self)
            } else {
                presentReplacementAlert(for: .username)
            }
        case let .guidedTourViewAction(action):
            state.guidedTourViewState.updateStateForGuidedTourViewAction(action)
        case let .identityFieldChanged(action):
            updateIdentityState(&state, for: action)
        case let .masterPasswordRePromptChanged(newValue):
            state.isMasterPasswordRePromptOn = newValue
        case let .morePressed(menuAction):
            handleMenuAction(menuAction)
        case let .nameChanged(newValue):
            state.name = newValue
        case .newCustomFieldPressed:
            presentCustomFieldAlert()
        case .newUriPressed:
            state.loginState.uris.append(UriState())
        case let .notesChanged(newValue):
            state.notes = newValue
        case let .ownerChanged(newValue):
            state.owner = newValue
        case let .passwordChanged(newValue):
            state.loginState.password = newValue
        case .removePasskeyPressed:
            state.loginState.fido2Credentials = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIAccessibility.post(notification: .announcement, argument: Localizations.passkeyRemoved)
            }
        case let .removeUriPressed(index):
            guard index < state.loginState.uris.count else { return }
            state.loginState.uris.remove(at: index)
        case let .togglePasswordVisibilityChanged(newValue):
            state.loginState.isPasswordVisible = newValue
            if newValue, !state.configuration.isAdding {
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledPasswordVisible,
                        cipherId: state.cipher.id
                    )
                }
            }
        case let .sshKeyItemAction(sshKeyAction):
            handleSSHKeyAction(sshKeyAction)
        case let .toastShown(newValue):
            state.toast = newValue
        case .totpFieldLeftFocus:
            parseAndValidateEditedAuthenticatorKey(state.loginState.totpState.rawAuthenticatorKeyString)
        case let .totpKeyChanged(newValue):
            state.loginState.totpState = LoginTOTPState(newValue)
        case let .typeChanged(newValue):
            state.type = newValue
            state.customFieldsState = AddEditCustomFieldsState(cipherType: newValue, customFields: [])
        case let .uriChanged(newValue, index: index):
            guard state.loginState.uris.count > index else { return }
            state.loginState.uris[index].uri = newValue
        case let .uriTypeChanged(newValue, index):
            guard index < state.loginState.uris.count else { return }
            state.loginState.uris[index].matchType = newValue
        case let .usernameChanged(newValue):
            state.loginState.username = newValue
        }
    }

    // MARK: Private Methods

    /// Handles dismissing the processor.
    ///
    /// - Parameter didAddItem: `true` if a new cipher was added or `false` if the user is
    ///     dismissing the view without saving.
    ///
    private func handleDismiss(didAddItem: Bool = false) {
        guard let appExtensionDelegate, appExtensionDelegate.isInAppExtensionSaveLoginFlow else {
            let shouldDismiss = delegate?.itemAdded() ?? true
            if shouldDismiss {
                coordinator.navigate(to: .dismiss())
            }
            return
        }

        if didAddItem, let username = state.cipher.login?.username, let password = state.cipher.login?.password {
            appExtensionDelegate.completeAutofillRequest(username: username, password: password, fields: nil)
        } else {
            appExtensionDelegate.didCancel()
        }
    }

    /// Fetches any additional data (e.g. organizations and folders) needed for adding or editing a cipher.
    private func fetchCipherOptions() async {
        do {
            let isPersonalOwnershipDisabled = await services.policyService.policyAppliesToUser(.personalOwnership)
            let ownershipOptions = try await services.vaultRepository
                .fetchCipherOwnershipOptions(includePersonal: !isPersonalOwnershipDisabled)

            // We need read-only collections so that we can include them in the state
            // to correctly calculate if the item can be deleted
            state.collections = try await services.vaultRepository.fetchCollections(includeReadOnly: true)
            // Filter out any collection IDs that aren't included in the fetched collections.
            state.collectionIds = state.collectionIds.filter { collectionId in
                state.collections.contains(where: { $0.id == collectionId })
            }

            state.isPersonalOwnershipDisabled = isPersonalOwnershipDisabled
            state.ownershipOptions = ownershipOptions
            if isPersonalOwnershipDisabled, state.organizationId == nil {
                // Only set the owner if personal ownership is disabled and there isn't already an
                // organization owner set. This prevents overwriting a preset owner when adding a
                // new item from a collection group view.
                state.owner = ownershipOptions.first
            }

            if !state.configuration.isAdding {
                await services.eventService.collect(eventType: .cipherClientViewed, cipherId: state.cipher.id)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Handles an action associated with the `AddEditCustomFieldsAction`.
    ///
    /// - Parameter action: The action that was sent from the `AddEditCustomFieldsView`.
    ///
    private func handleCustomFieldAction(_ action: AddEditCustomFieldsAction) { // swiftlint:disable:this cyclomatic_complexity line_length
        switch action {
        case let .booleanFieldChanged(newValue, index):
            guard state.customFieldsState.customFields.indices.contains(index) else { return }
            state.customFieldsState.customFields[index].value = String(newValue).lowercased()
        case let .customFieldAdded(type, name):
            var customFieldState = CustomFieldState(name: name, type: type)
            if type == .linked {
                customFieldState.linkedIdType = LinkedIdType.getLinkedIdType(for: state.type).first
            }
            state.customFieldsState.customFields.append(customFieldState)
        case let .customFieldChanged(newValue, index: index):
            guard state.customFieldsState.customFields.indices.contains(index) else { return }
            state.customFieldsState.customFields[index].value = newValue
        case let .customFieldNameChanged(index, newValue):
            guard state.customFieldsState.customFields.indices.contains(index) else { return }
            state.customFieldsState.customFields[index].name = newValue
        case let .editCustomFieldNamePressed(index: index):
            guard state.customFieldsState.customFields.indices.contains(index) else { return }
            presentEditCustomFieldNameAlert(oldName: state.customFieldsState.customFields[index].name, index: index)
        case let .moveDownCustomFieldPressed(index: index):
            guard state.customFieldsState.customFields.indices.contains(index),
                  index != state.customFieldsState.customFields.indices.last else { return }
            state.customFieldsState.customFields.swapAt(index, index + 1)
        case let .moveUpCustomFieldPressed(index: index):
            guard state.customFieldsState.customFields.indices.contains(index),
                  index != state.customFieldsState.customFields.indices.first else { return }
            state.customFieldsState.customFields.swapAt(index, index - 1)
        case .newCustomFieldPressed:
            presentCustomFieldAlert()
        case let .removeCustomFieldPressed(index):
            guard state.customFieldsState.customFields.indices.contains(index) else { return }
            state.customFieldsState.customFields.remove(at: index)
        case let .selectedCustomFieldType(type):
            presentNameCustomFieldAlert(fieldType: type)
        case let .selectedLinkedIdType(index, idType):
            guard state.customFieldsState.customFields.indices.contains(index),
                  state.customFieldsState.customFields[index].type == .linked else { return }
            state.customFieldsState.customFields[index].linkedIdType = idType
        case let .togglePasswordVisibilityChanged(isPasswordVisible, index):
            guard state.customFieldsState.customFields.indices.contains(index) else { return }
            state.customFieldsState.customFields[index].isPasswordVisible = isPasswordVisible
            if isPasswordVisible {
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledHiddenFieldVisible,
                        cipherId: state.cipher.id
                    )
                }
            }
        }
    }

    /// Handles an action associated with the `VaultItemManagementMenuAction` menu.
    ///
    /// - Parameter action: The action that was sent from the menu.
    ///
    private func handleMenuAction(_ action: VaultItemManagementMenuAction) {
        switch action {
        case .attachments:
            coordinator.navigate(to: .attachments(state.cipher))
        case .clone:
            // we don't show clone option in edit item state
            break
        case .editCollections:
            coordinator.navigate(to: .editCollections(state.cipher), context: self)
        case .moveToOrganization:
            coordinator.navigate(to: .moveToOrganization(state.cipher), context: self)
        }
    }

    /// Handles `ViewSSHKeyItemAction` events.
    /// - Parameter sshKeyAction: The action to handle
    private func handleSSHKeyAction(_ sshKeyAction: ViewSSHKeyItemAction) {
        switch sshKeyAction {
        case .copyPressed:
            return
        case .privateKeyVisibilityPressed:
            state.sshKeyState.isPrivateKeyVisible.toggle()
            // TODO: PM-11977 Collect visibility toggled event
        }
    }

    /// Receives an `AddEditCardItem` action from the `AddEditCardView` view's store, and updates
    /// the `AddEditCardState`.
    ///
    /// - Parameters:
    ///   - state: The parent `AddEditCardState` to be updated.
    ///   - action: The `AddEditCardItemAction` received.
    private func updateCardState(_ state: inout AddEditItemState, for action: AddEditCardItemAction) {
        switch action {
        case let .brandChanged(brand):
            state.cardItemState.brand = brand
        case let .cardholderNameChanged(name):
            state.cardItemState.cardholderName = name
        case let .cardNumberChanged(number):
            state.cardItemState.cardNumber = number
        case let .cardSecurityCodeChanged(code):
            state.cardItemState.cardSecurityCode = code
        case let .expirationMonthChanged(month):
            state.cardItemState.expirationMonth = month
        case let .expirationYearChanged(year):
            state.cardItemState.expirationYear = year
        case let .toggleCodeVisibilityChanged(isVisible):
            state.cardItemState.isCodeVisible = isVisible
            if isVisible {
                let cipherId = state.cipher.id
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledCardCodeVisible,
                        cipherId: cipherId
                    )
                }
            }
        case let .toggleNumberVisibilityChanged(isVisible):
            state.cardItemState.isNumberVisible = isVisible
            if isVisible {
                let cipherId = state.cipher.id
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledCardNumberVisible,
                        cipherId: cipherId
                    )
                }
            }
        }
    }

    /// Receives an `AddEditIdentityItem` action from the `AddEditIdentityView` view's store, and updates
    /// the `AddEditIdentityState`.
    ///
    /// - Parameters:
    ///   - state: The parent `AddEditItemState` to be updated.
    ///   - action: The `AddEditIdentityItemAction` received.
    private func updateIdentityState(_ state: inout AddEditItemState, for action: AddEditIdentityItemAction) {
        switch action {
        case let .firstNameChanged(firstName):
            state.identityState.firstName = firstName
        case let .middleNameChanged(middleName):
            state.identityState.middleName = middleName
        case let .titleChanged(title):
            state.identityState.title = title
        case let .lastNameChanged(lastName):
            state.identityState.lastName = lastName
        case let .userNameChanged(userName):
            state.identityState.userName = userName
        case let .companyChanged(company):
            state.identityState.company = company
        case let .socialSecurityNumberChanged(ssn):
            state.identityState.socialSecurityNumber = ssn
        case let .passportNumberChanged(passportNumber):
            state.identityState.passportNumber = passportNumber
        case let .licenseNumberChanged(licenseNumber):
            state.identityState.licenseNumber = licenseNumber
        case let .emailChanged(email):
            state.identityState.email = email
        case let .phoneNumberChanged(phoneNumber):
            state.identityState.phone = phoneNumber
        case let .address1Changed(address1):
            state.identityState.address1 = address1
        case let .address2Changed(address2):
            state.identityState.address2 = address2
        case let .address3Changed(address3):
            state.identityState.address3 = address3
        case let .cityOrTownChanged(cityOrTown):
            state.identityState.cityOrTown = cityOrTown
        case let .stateChanged(stateProvince):
            state.identityState.state = stateProvince
        case let .postalCodeChanged(postalCode):
            state.identityState.postalCode = postalCode
        case let .countryChanged(country):
            state.identityState.country = country
        }
    }

    /// Checks the eligibility of the Learn New Login action card.
    ///
    private func checkLearnNewLoginActionCardEligibility() async {
        if await services.configService.getFeatureFlag(.nativeCreateAccountFlow),
           appExtensionDelegate == nil {
            state.isLearnNewLoginActionCardEligible = await services.stateService
                .getLearnNewLoginActionCardStatus() == .incomplete
        }
    }

    /// Checks the password currently stored in `state`.
    ///
    private func checkPassword() async {
        coordinator.showLoadingOverlay(title: Localizations.checkingPassword)
        defer { coordinator.hideLoadingOverlay() }
        do {
            let breachCount = try await services.apiService.checkDataBreaches(password: state.loginState.password)
            coordinator.showAlert(.dataBreachesCountAlert(count: breachCount))
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Builds an actions sheet for creating a new custom field and then routes the coordinator
    /// to the `.alert` route.
    ///
    private func presentCustomFieldAlert() {
        let actions = state.type.allowedFieldTypes.map { type in
            AlertAction(title: type.localizedName, style: .default) { [weak self] _ in
                guard let self else { return }
                receive(
                    .customField(
                        .selectedCustomFieldType(type)
                    )
                )
            }
        }

        let alertActions = actions + [AlertAction(title: Localizations.cancel, style: .cancel)]

        let alert = Alert(
            title: Localizations.selectTypeField,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions
        )
        coordinator.showAlert(alert)
    }

    /// Builds an alert to edit  name of a custom field and then routes the coordinator
    /// to the `.alert` route.
    ///
    private func presentEditCustomFieldNameAlert(oldName: String?, index: Int) {
        let alert = Alert.nameCustomFieldAlert(text: oldName) { [weak self] name in
            guard let self else { return }
            receive(
                .customField(
                    .customFieldNameChanged(
                        index: index,
                        newValue: name
                    )
                )
            )
        }
        coordinator.showAlert(alert)
    }

    /// Builds an alert to name a new custom field and then routes the coordinator
    /// to the `.alert` route.
    ///
    private func presentNameCustomFieldAlert(fieldType: FieldType) {
        let alert = Alert.nameCustomFieldAlert { [weak self] name in
            guard let self else { return }
            receive(.customField(.customFieldAdded(fieldType, name)))
        }
        coordinator.showAlert(alert)
    }

    /// Builds and navigates to an alert for overwriting an existing value for the specified type.
    ///
    /// - Parameter type: The `GeneratorType` that is being overwritten.
    ///
    private func presentReplacementAlert(for type: GeneratorType) {
        let title = switch type {
        case .passphrase, .password:
            Localizations.passwordOverrideAlert
        case .username:
            Localizations.areYouSureYouWantToOverwriteTheCurrentUsername
        }

        let alert = Alert(
            title: title,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.no, style: .default),
                AlertAction(
                    title: Localizations.yes,
                    style: .default,
                    handler: { [weak self] _ in
                        let emailWebsite = self?.state.loginState.generatorEmailWebsite
                        self?.coordinator.navigate(to: .generator(type, emailWebsite: emailWebsite), context: self)
                    }
                ),
            ]
        )
        coordinator.showAlert(alert)
    }

    /// Saves the item currently stored in `state`.
    ///
    private func saveItem() async {
        guard state.cipher.organizationId == nil || !state.cipher.collectionIds.isEmpty else {
            coordinator.showAlert(
                .defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.selectOneCollection
                )
            )
            return
        }

        defer { coordinator.hideLoadingOverlay() }
        do {
            try EmptyInputValidator(fieldName: Localizations.name)
                .validate(input: state.name)

            let userVerified = try await fido2CheckUserIfNeeded()

            coordinator.showLoadingOverlay(title: Localizations.saving)
            switch state.configuration {
            case .add:
                try await addItem(fido2UserVerified: userVerified)
            case let .existing(cipherView):
                try await updateItem(cipherView: cipherView)
            }
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
            return
        } catch UserVerificationError.cancelled {
            return
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Adds the item currently in `state`.
    ///
    private func addItem(fido2UserVerified: Bool) async throws {
        if let autofillAppExtensionDelegate = appExtensionDelegate as? AutofillAppExtensionDelegate,
           autofillAppExtensionDelegate.isCreatingFido2Credential {
            services.fido2UserInterfaceHelper.pickedCredentialForCreation(
                result: .success(
                    CheckUserAndPickCredentialForCreationResult(
                        cipher: CipherViewWrapper(cipher: state.cipher),
                        checkUserResult: CheckUserResult(userPresent: true, userVerified: fido2UserVerified)
                    )
                )
            )
            return
        }

        try await services.vaultRepository.addCipher(state.cipher)
        coordinator.hideLoadingOverlay()
        handleDismiss(didAddItem: true)
        await services.reviewPromptService.trackUserAction(.addedNewItem)
    }

    /// Checks user verification if needed on Fido2 flows.
    private func fido2CheckUserIfNeeded() async throws -> Bool {
        guard let autofillAppExtensionDelegate = appExtensionDelegate as? AutofillAppExtensionDelegate,
              autofillAppExtensionDelegate.isCreatingFido2Credential,
              let fido2CreationOptions = services.fido2UserInterfaceHelper.fido2CreationOptions else {
            return false
        }

        let result = try await services.fido2UserInterfaceHelper.checkUser(
            userVerificationPreference: fido2CreationOptions.requireVerification,
            credential: state.cipher,
            shouldThrowEnforcingRequiredVerification: true
        )
        return result.userVerified
    }

    /// Soft Deletes the item currently stored in `state`.
    ///
    private func softDeleteItem() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(title: Localizations.softDeleting)
            try await services.vaultRepository.softDeleteCipher(state.cipher)
            coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
                self?.delegate?.itemSoftDeleted()
            })))
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Shows the password autofill information alert if it hasn't been shown before and the user
    /// is adding a new login in the app.
    ///
    private func showPasswordAutofillAlertIfNeeded() async {
        guard await !services.stateService.getAddSitePromptShown(),
              state.configuration == .add,
              state.type == .login,
              !(appExtensionDelegate?.isInAppExtension ?? false) else {
            return
        }
        coordinator.showAlert(.passwordAutofillInformation())
        await services.stateService.setAddSitePromptShown(true)
    }

    /// Stream the list of folders.
    ///
    private func streamFolders() async {
        do {
            for try await folders in try await services.settingsRepository.foldersListPublisher() {
                state.folders = [.default] + folders.map { DefaultableType.custom($0) }
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Check if the user has a master password and set showMasterPasswordReprompt accordingly
    ///
    private func checkIfUserHasMasterPassword() async {
        do {
            state.showMasterPasswordReprompt = try await services.authRepository.hasMasterPassword()
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Shows a soft delete cipher confirmation alert.
    ///
    private func showSoftDeleteConfirmation() async {
        let alert = Alert.deleteCipherConfirmation(isSoftDelete: true) { [weak self] in
            guard let self else { return }
            await softDeleteItem()
        }
        coordinator.showAlert(alert)
    }

    /// Updates the item currently in `state`.
    ///
    private func updateItem(cipherView: CipherView) async throws {
        try await services.vaultRepository.updateCipher(cipherView.updatedView(with: state))
        coordinator.hideLoadingOverlay()
        let shouldDismissed = delegate?.itemUpdated() ?? true
        if shouldDismissed {
            coordinator.navigate(to: .dismiss())
        }
    }

    /// Kicks off the TOTP setup flow.
    ///
    private func setupTotp() async {
        guard services.cameraService.deviceSupportsCamera(),
              appExtensionDelegate?.isInAppExtension != true // Extensions don't allow camera access.
        else {
            coordinator.navigate(to: .setupTotpManual, context: self)
            return
        }
        let status = await services.cameraService.checkStatusOrRequestCameraAuthorization()
        if status == .authorized {
            await coordinator.handleEvent(.showScanCode, context: self)
        } else {
            coordinator.navigate(to: .setupTotpManual, context: self)
        }
    }
}

extension AddEditItemProcessor: GeneratorCoordinatorDelegate {
    func didCancelGenerator() {
        coordinator.navigate(to: .dismiss())
    }

    func didCompleteGenerator(for type: GeneratorType, with value: String) {
        switch type {
        case .passphrase,
             .password:
            state.loginState.password = value
        case .username:
            state.loginState.username = value
        }
        coordinator.navigate(to: .dismiss())
    }
}

// MARK: - AddEditFolderDelegate

extension AddEditItemProcessor: AddEditFolderDelegate {
    func folderAdded(_ folderView: FolderView) {
        state.folder = .custom(folderView)
    }

    func folderDeleted() {
        // No-op: deleting a folder isn't supported from the add folder flow.
    }

    func folderEdited() {
        // No-op: editing a folder isn't supported from the add folder flow.
    }
}

extension AddEditItemProcessor: AuthenticatorKeyCaptureDelegate {
    func didCompleteCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        with value: String
    ) {
        let dismissAction = DismissAction(action: { [weak self] in
            self?.parseAndValidateCapturedAuthenticatorKey(value)
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }

    func parseAndValidateCapturedAuthenticatorKey(_ key: String) {
        do {
            let authKeyModel = try services.totpService.getTOTPConfiguration(key: key)
            state.loginState.totpState = .key(authKeyModel)
            state.toast = Toast(title: Localizations.authenticatorKeyAdded)
        } catch {
            coordinator.showAlert(.totpScanFailureAlert())
        }
    }

    func parseAndValidateEditedAuthenticatorKey(_ key: String?) {
        guard key != state.loginState.totpState.authKeyModel?.rawAuthenticatorKey else { return }
        let newState = LoginTOTPState(key)
        state.loginState.totpState = newState
        coordinator.showAlert(.totpScanFailureAlert())
    }

    func showCameraScan(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    ) {
        guard services.cameraService.deviceSupportsCamera() else { return }
        let dismissAction = DismissAction(action: { [weak self] in
            guard let self else { return }
            Task {
                await self.coordinator.handleEvent(.showScanCode, context: self)
            }
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }

    func showManualEntry(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    ) {
        let dismissAction = DismissAction(action: { [weak self] in
            self?.coordinator.navigate(to: .setupTotpManual, context: self)
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }
}

// MARK: - EditCollectionsProcessorDelegate

extension AddEditItemProcessor: EditCollectionsProcessorDelegate {
    func didUpdateCipher() {
        state.toast = Toast(title: Localizations.itemUpdated)
    }
}

// MARK: - MoveToOrganizationProcessorDelegate

extension AddEditItemProcessor: MoveToOrganizationProcessorDelegate {
    func didMoveCipher(_ cipher: CipherView, to organization: CipherOwner) {
        state.toast = Toast(title: Localizations.movedItemToOrg(cipher.name, organization.localizedName))
    }
} // swiftlint:disable:this file_length
