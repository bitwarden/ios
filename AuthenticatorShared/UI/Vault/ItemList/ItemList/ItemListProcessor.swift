import Foundation

// swiftlint:disable file_length

// MARK: - ItemListProcessor

/// A `Processor` that can process `ItemListAction` and `ItemListEffect` objects.
final class ItemListProcessor: StateProcessor<ItemListState, ItemListAction, ItemListEffect> {
    // MARK: Types

    typealias Services = HasAuthenticatorItemRepository
        & HasCameraService
        & HasErrorReporter
        & HasPasteboardService
        & HasTOTPService
        & HasTimeProvider

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private var coordinator: AnyCoordinator<ItemListRoute, ItemListEvent>

    /// The services for this processor.
    private var services: Services

    /// An object to manage TOTP code expirations and batch refresh calls for the group.
    private var groupTotpExpirationManager: TOTPExpirationManager?

    // MARK: Initialization

    /// Creates a new `ItemListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services for this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<ItemListRoute, ItemListEvent>,
        services: Services,
        state: ItemListState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
        groupTotpExpirationManager = .init(
            timeProvider: services.timeProvider,
            onExpiration: { [weak self] expiredItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(for: expiredItems)
                }
            }
        )
    }

    // MARK: Methods

    override func perform(_ effect: ItemListEffect) async {
        switch effect {
        case .addItemPressed:
            await setupTotp()
        case .appeared:
            await streamItemList()
        case let .copyPressed(item):
            switch item.itemType {
            case let .totp(model):
                guard let key = model.itemView.totpKey,
                      let totpKey = TOTPKeyModel(authenticatorKey: key)
                else { return }
                await generateAndCopyTotpCode(totpKey: totpKey)
            }
        case .refresh:
            await streamItemList()
        case let .search(text):
            state.searchResults = await searchItems(for: text)
        case .streamItemList:
            await streamItemList()
        }
    }

    override func receive(_ action: ItemListAction) {
        switch action {
        case .clearURL:
            break
        case let .deletePressed(item):
            confirmDeleteItem(item.id)
        case let .editPressed(item):
            guard case let .totp(model) = item.itemType else { return }
            coordinator.navigate(to: .editItem(item: model.itemView), context: self)
        case let .itemPressed(item):
            switch item.itemType {
            case let .totp(model):
                services.pasteboardService.copy(model.totpCode.code)
                state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
            }
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else {
                state.searchText = ""
                state.searchResults = []
                return
            }
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Confirm that the user wants to delete the item then delete it if so
    private func confirmDeleteItem(_ id: String) {
        coordinator.showAlert(.confirmDeleteItem {
            await self.deleteItem(id)
        })
    }

    /// Delete the item
    private func deleteItem(_ id: String) async {
        do {
            try await services.authenticatorItemRepository.deleteAuthenticatorItem(id)
            state.toast = Toast(text: Localizations.itemDeleted)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Generates and copies a TOTP code for the cipher's TOTP key.
    ///
    /// - Parameter totpKey: The TOTP key used to generate a TOTP code.
    ///
    private func generateAndCopyTotpCode(totpKey: TOTPKeyModel) async {
        do {
            let code = try await services.totpService.getTotpCode(for: totpKey)
            services.pasteboardService.copy(code.code)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [ItemListItem]) async {
        guard case .data = state.loadingState else { return }
        let refreshedItems = await items.asyncMap { item in
            guard case let .totp(model) = item.itemType,
                  let key = model.itemView.totpKey,
                  let keyModel = TOTPKeyModel(authenticatorKey: key),
                  let code = try? await services.totpService.getTotpCode(for: keyModel)
            else {
                services.errorReporter.log(error: TOTPServiceError
                    .unableToGenerateCode("Unable to refresh TOTP code for list view item: \(item.id)"))
                return item
            }
            var updatedModel = model
            updatedModel.totpCode = code
            return ItemListItem(
                id: item.id,
                name: item.name,
                accountName: keyModel.accountName,
                itemType: .totp(model: updatedModel)
            )
        }
        groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: refreshedItems)
        state.loadingState = .data(refreshedItems)
    }

    /// Kicks off the TOTP setup flow.
    ///
    private func setupTotp() async {
        guard services.cameraService.deviceSupportsCamera() else {
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

    /// Handle the result of the selected option on the More Options alert.
    ///
    /// - Parameter action: The selected action.
    ///
    private func handleMoreOptionsAction(_ action: MoreOptionsAction) async {
        switch action {
        case let .copyTotp(totpKey):
            await generateAndCopyTotpCode(totpKey: totpKey)
        case let .delete(id):
            confirmDeleteItem(id)
        case let .edit(item):
            coordinator.navigate(to: .editItem(item: item), context: self)
        }
    }

    /// Searches items using the provided string, and returns any matching results.
    ///
    /// - Parameters:
    ///   - searchText: The string to use when searching items.
    /// - Returns: An array of `ItemListItem` objects. If no results can be found, an empty array will be returned.
    ///
    private func searchItems(for searchText: String) async -> [ItemListItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        do {
            let result = try await services.authenticatorItemRepository.searchItemListPublisher(
                searchText: searchText
            )
            for try await items in result {
                return items
            }
        } catch {
            services.errorReporter.log(error: error)
        }
        return []
    }

    /// Stream the items list.
    private func streamItemList() async {
        do {
            for try await value in try await services.authenticatorItemRepository.itemListPublisher() {
                guard let items = value.first?.items else { return }
                let itemList = try await items.asyncMap { item in
                    guard case let .totp(model) = item.itemType,
                          let key = model.itemView.totpKey,
                          let keyModel = TOTPKeyModel(authenticatorKey: key)
                    else { return item }
                    let code = try await services.totpService.getTotpCode(for: keyModel)
                    var updatedModel = model
                    updatedModel.totpCode = code
                    return ItemListItem(
                        id: item.id,
                        name: item.name,
                        accountName: keyModel.accountName,
                        itemType: .totp(model: updatedModel)
                    )
                }
                groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: itemList)
                state.loadingState = .data(itemList)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

/// A class to manage TOTP code expirations for the ItemListProcessor and batch refresh calls.
///
private class TOTPExpirationManager {
    // MARK: Properties

    /// A closure to call on expiration
    ///
    var onExpiration: (([ItemListItem]) -> Void)?

    // MARK: Private Properties

    /// All items managed by the object, grouped by TOTP period.
    ///
    private(set) var itemsByInterval = [UInt32: [ItemListItem]]()

    /// A model to provide time to calculate the countdown.
    ///
    private var timeProvider: any TimeProvider

    /// A timer that triggers `checkForExpirations` to manage code expirations.
    ///
    private var updateTimer: Timer?

    /// Initializes a new countdown timer
    ///
    /// - Parameters
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///         Used to calculate time remaining for a present TOTP code.
    ///   - onExpiration: A closure to call on code expiration for a list of vault items.
    ///
    init(
        timeProvider: any TimeProvider,
        onExpiration: (([ItemListItem]) -> Void)?
    ) {
        self.timeProvider = timeProvider
        self.onExpiration = onExpiration
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true,
            block: { _ in
                self.checkForExpirations()
            }
        )
    }

    /// Clear out any timers tracking TOTP code expiration
    deinit {
        cleanup()
    }

    // MARK: Methods

    /// Configures TOTP code refresh scheduling
    ///
    /// - Parameter items: The vault list items that may require code expiration tracking.
    ///
    func configureTOTPRefreshScheduling(for items: [ItemListItem]) {
        var newItemsByInterval = [UInt32: [ItemListItem]]()
        items.forEach { item in
            guard case let .totp(model) = item.itemType else { return }
            newItemsByInterval[model.totpCode.period, default: []].append(item)
        }
        itemsByInterval = newItemsByInterval
    }

    /// A function to remove any outstanding timers
    ///
    func cleanup() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func checkForExpirations() {
        var expired = [ItemListItem]()
        var notExpired = [UInt32: [ItemListItem]]()
        itemsByInterval.forEach { period, items in
            let sortedItems: [Bool: [ItemListItem]] = TOTPExpirationCalculator.listItemsByExpiration(
                items,
                timeProvider: timeProvider
            )
            expired.append(contentsOf: sortedItems[true] ?? [])
            notExpired[period] = sortedItems[false]
        }
        itemsByInterval = notExpired
        guard !expired.isEmpty else { return }
        onExpiration?(expired)
    }
}

extension ItemListProcessor: AuthenticatorKeyCaptureDelegate {
    func didCompleteAutomaticCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String
    ) {
        let dismissAction = DismissAction(action: { [weak self] in
            Task {
                await self?.parseAndValidateAutomaticCaptureKey(key)
            }
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }

    func parseAndValidateAutomaticCaptureKey(_ key: String) async {
        do {
            let authKeyModel = try services.totpService.getTOTPConfiguration(key: key)
            let loginTotpState = LoginTOTPState(authKeyModel: authKeyModel)

            guard let key = loginTotpState.rawAuthenticatorKeyString
            else { return }

            let itemName = authKeyModel.issuer ?? authKeyModel.accountName ?? ""
            let newItem = AuthenticatorItemView(id: UUID().uuidString, name: itemName, totpKey: key)
            try await services.authenticatorItemRepository.addAuthenticatorItem(newItem)
            await perform(.refresh)
            state.toast = Toast(text: Localizations.authenticatorKeyAdded)
        } catch {
            coordinator.showAlert(.totpScanFailureAlert())
        }
    }

    func didCompleteManualCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String,
        name: String
    ) {
        let dismissAction = DismissAction(action: { [weak self] in
            Task {
                await self?.parseAndValidateManualKey(key: key, name: name)
            }
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }

    func parseAndValidateManualKey(key: String, name: String) async {
        do {
            let authKeyModel = try services.totpService.getTOTPConfiguration(key: key)
            let loginTotpState: LoginTOTPState
            switch authKeyModel.totpKey {
            case let .base32(key):
                let newOtpAuthUri = OTPAuthModel(issuer: name, secret: key)
                let newKeyModel = try services.totpService.getTOTPConfiguration(key: newOtpAuthUri.otpAuthUri)
                loginTotpState = LoginTOTPState(authKeyModel: newKeyModel)
            case .otpAuthUri, .steamUri:
                loginTotpState = LoginTOTPState(authKeyModel: authKeyModel)
            }

            guard let key = loginTotpState.rawAuthenticatorKeyString
            else { return }

            let itemName = name
            let newItem = AuthenticatorItemView(id: UUID().uuidString, name: itemName, totpKey: key)
            try await services.authenticatorItemRepository.addAuthenticatorItem(newItem)
            await perform(.refresh)

            state.toast = Toast(text: Localizations.authenticatorKeyAdded)
        } catch {
            coordinator.showAlert(.totpScanFailureAlert())
        }
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

// MARK: - MoreOptionsAction

/// The actions available from the More Options alert.
enum MoreOptionsAction: Equatable {
    /// Generate and copy the TOTP code for the given `totpKey`.
    case copyTotp(totpKey: TOTPKeyModel)

    /// Delete the item with the given `id`
    case delete(id: String)

    /// Navigate to the view to edit the `AuthenticatorItemView`.
    case edit(authenticatorItemView: AuthenticatorItemView)
}

// MARK: - EditAuthenticatorItemViewDelegate

extension ItemListProcessor: AuthenticatorItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(text: Localizations.itemDeleted)
    }
}
