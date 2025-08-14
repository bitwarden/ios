import BitwardenKit
import BitwardenResources
import Combine
import Foundation

// swiftlint:disable file_length

// MARK: - ItemListProcessor

/// A `Processor` that can process `ItemListAction` and `ItemListEffect` objects.
final class ItemListProcessor: StateProcessor<ItemListState, ItemListAction, ItemListEffect> {
    // swiftlint:disable:previous type_body_length

    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasApplication
        & HasAuthenticatorItemRepository
        & HasCameraService
        & HasConfigService
        & HasErrorReporter
        & HasNotificationCenterService
        & HasPasteboardService
        & HasTOTPService
        & HasTimeProvider

    // MARK: Private Properties

    /// The set to hold Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

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
        groupTotpExpirationManager = TOTPExpirationManager(
            timeProvider: services.timeProvider,
            onExpiration: { [weak self] expiredItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(for: expiredItems)
                }
            }
        )
        setupForegroundNotification()
    }

    deinit {
        groupTotpExpirationManager?.cleanup()
        groupTotpExpirationManager = nil
    }

    // MARK: Methods

    override func perform(_ effect: ItemListEffect) async {
        switch effect {
        case .addItemPressed:
            await setupTotp()
        case .appeared:
            await determineItemListCardState()
            await streamItemList()
        case let .closeCard(card):
            services.appSettingsStore.setCardClosedState(card: card)
            await determineItemListCardState()
        case let .copyPressed(item):
            switch item.itemType {
            case let .sharedTotp(model):
                guard let key = model.itemView.totpKey,
                      let totpKey = TOTPKeyModel(authenticatorKey: key)
                else { return }
                await generateAndCopyTotpCode(totpKey: totpKey)
            case .syncError:
                break // no action for this type
            case let .totp(model):
                guard let key = model.itemView.totpKey,
                      let totpKey = TOTPKeyModel(authenticatorKey: key)
                else { return }
                await generateAndCopyTotpCode(totpKey: totpKey)
            }
        case let .moveToBitwardenPressed(item):
            guard case let .totp(model) = item.itemType else { return }
            await moveItemToBitwarden(item: model.itemView)
        case .refresh:
            await determineItemListCardState()
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
            state.url = nil
        case let .deletePressed(item):
            guard case .totp = item.itemType else { return }
            confirmDeleteItem(item.id)
        case let .editPressed(item):
            guard case let .totp(model) = item.itemType else { return }
            coordinator.navigate(to: .editItem(item: model.itemView), context: self)
        case let .itemPressed(item):
            guard let totpCode = item.totpCodeModel else { return }

            services.pasteboardService.copy(totpCode.code)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
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
            if !state.searchText.isEmpty {
                state.searchResults = await searchItems(for: state.searchText)
            }
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

    /// Store the item in the shared sync data store as a temporary item and deeplink to the Bitwarden app to
    /// let the user choose where to store it.
    ///
    /// - Parameter item: the item to be moved.
    ///
    private func moveItemToBitwarden(item: AuthenticatorItemView) async {
        guard await services.authenticatorItemRepository.isPasswordManagerSyncActive(),
              let application = services.application,
              application.canOpenURL(ExternalLinksConstants.passwordManagerScheme)
        else { return }

        do {
            try await services.authenticatorItemRepository.saveTemporarySharedItem(item)
            state.url = ExternalLinksConstants.passwordManagerNewItem
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [ItemListItem]) async {
        guard case let .data(currentSections) = state.loadingState else { return }
        do {
            let refreshedItems = try await services.authenticatorItemRepository.refreshTotpCodes(on: items)
            let updatedSections = currentSections.updated(with: refreshedItems)
            let allItems = updatedSections.flatMap(\.items)
            groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: allItems)
            state.loadingState = .data(updatedSections)
            if !state.searchResults.isEmpty {
                state.searchResults = await searchItems(for: state.searchText)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
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
                let itemList = try await services.authenticatorItemRepository.refreshTotpCodes(on: items)
                groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: itemList)
                return itemList
            }
        } catch {
            services.errorReporter.log(error: error)
        }
        return []
    }

    /// Subscribe to receive foreground notifications so that we can refresh the item list when the app is relaunched.
    ///
    private func setupForegroundNotification() {
        services.notificationCenterService
            .willEnterForegroundPublisher()
            .sink { [weak self] in
                guard let self else { return }
                Task {
                    await self.perform(.refresh)
                }
            }
            .store(in: &cancellables)
    }

    /// Determine if the user has synced with this account previously. If they have not synced previously,
    /// this method return `true` indicating that we should show the toast for a newly synced account. It
    /// also stores the fact that we've synced with this account in the `AppSettingsStore` for
    /// future reference so that we only show the toast on *first* sync.
    ///
    /// For any local code sections or for accounts the user has previously synced with, this method will return
    /// `false` so that we do not show the toast.
    ///
    /// - Parameter name: The name of the account to evaluate. This is the section header shown to the user.
    /// - Returns: `true` if the accounts synced toast should be shown to the user, `false` otherwise.
    ///
    private func shouldShowAccountSyncToast(name: String) -> Bool {
        guard !name.isEmpty,
              name != Localizations.localCodes,
              name != Localizations.favorites
        else { return false }

        if !services.appSettingsStore.hasSyncedAccount(name: name) {
            services.appSettingsStore.setHasSyncedAccount(name: name)
            return true
        } else {
            return false
        }
    }

    /// Stream the items list.
    private func streamItemList() async {
        do {
            var showToast = false
            for try await value in try await services.authenticatorItemRepository.itemListPublisher() {
                let sectionList = try await value.asyncMap { section in
                    if shouldShowAccountSyncToast(name: section.name) {
                        showToast = true
                    }
                    let itemList = try await services.authenticatorItemRepository.refreshTotpCodes(on: section.items)
                    let sortedList = itemList.sorted(by: ItemListItem.localizedNameComparator)
                    return ItemListSection(id: section.id, items: sortedList, name: section.name)
                }
                groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: sectionList.flatMap(\.items))
                state.showMoveToBitwarden = await services.authenticatorItemRepository.isPasswordManagerSyncActive()
                state.loadingState = .data(sectionList)
                if showToast {
                    state.toast = Toast(text: Localizations.accountsSyncedFromBitwardenApp)
                }
                if !state.searchText.isEmpty {
                    state.searchResults = await searchItems(for: state.searchText)
                }
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Determine if the ItemListCard should be shown and which state to show.
    ///
    private func determineItemListCardState() async {
        guard await !services.authenticatorItemRepository.isPasswordManagerSyncActive(),
              let application = services.application else {
            state.itemListCardState = .none
            return
        }

        let passwordManagerInstalled = application.canOpenURL(ExternalLinksConstants.passwordManagerScheme)
        let hasClosedDownloadCard = services.appSettingsStore.cardClosedState(card: .passwordManagerDownload)
        let hasClosedSyncCard = services.appSettingsStore.cardClosedState(card: .passwordManagerSync)

        if !passwordManagerInstalled, !hasClosedDownloadCard {
            state.itemListCardState = .passwordManagerDownload
        } else if passwordManagerInstalled, !hasClosedSyncCard {
            state.itemListCardState = .passwordManagerSync
        } else {
            state.itemListCardState = .none
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
            if let totpCodeModel = item.totpCodeModel {
                newItemsByInterval[totpCodeModel.period, default: []].append(item)
            }
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
        Task {
            guard await services.authenticatorItemRepository.isPasswordManagerSyncActive() else {
                captureCoordinator.navigate(
                    to: .dismiss(parseKeyAndDismiss(key, sendToBitwarden: false))
                )
                return
            }

            if services.appSettingsStore.hasSeenDefaultSaveOptionPrompt {
                switch services.appSettingsStore.defaultSaveOption {
                case .saveHere:
                    captureCoordinator.navigate(to: .dismiss(parseKeyAndDismiss(key, sendToBitwarden: false)))
                case .saveToBitwarden:
                    captureCoordinator.navigate(to: .dismiss(parseKeyAndDismiss(key, sendToBitwarden: true)))
                case .none:
                    coordinator.showAlert(.determineScanSaveLocation(
                        saveLocallyAction: { [weak self] in
                            captureCoordinator.navigate(
                                to: .dismiss(self?.parseKeyAndDismiss(key, sendToBitwarden: false))
                            )
                        }, sendToBitwardenAction: { [weak self] in
                            captureCoordinator.navigate(
                                to: .dismiss(self?.parseKeyAndDismiss(key, sendToBitwarden: true))
                            )
                        }
                    ))
                }
            } else {
                coordinator.showAlert(.determineScanSaveLocation(
                    saveLocallyAction: { [weak self] in
                        let dismissAction = DismissAction(action: { [weak self] in
                            self?.confirmDefaultSaveAlert(key: key, sendToBitwarden: false)
                        })
                        captureCoordinator.navigate(to: .dismiss(dismissAction))
                    }, sendToBitwardenAction: { [weak self] in
                        let dismissAction = DismissAction(action: { [weak self] in
                            self?.confirmDefaultSaveAlert(key: key, sendToBitwarden: true)
                        })
                        captureCoordinator.navigate(to: .dismiss(dismissAction))
                    }
                ))
            }
        }
    }

    func parseAndValidateAutomaticCaptureKey(_ key: String, sendToBitwarden: Bool) async {
        do {
            let authKeyModel = try services.totpService.getTOTPConfiguration(key: key)
            let loginTotpState = LoginTOTPState(authKeyModel: authKeyModel)

            guard let key = loginTotpState.rawAuthenticatorKeyString
            else { return }

            let itemName = authKeyModel.issuer ?? authKeyModel.accountName ?? ""
            let accountName = itemName == authKeyModel.accountName ? nil : authKeyModel.accountName
            let newItem = AuthenticatorItemView(
                favorite: false,
                id: UUID().uuidString,
                name: itemName,
                totpKey: key,
                username: accountName
            )
            try await storeNewItem(newItem, sendToBitwarden: sendToBitwarden)
        } catch {
            coordinator.showAlert(.totpScanFailureAlert())
        }
    }

    func didCompleteManualCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String,
        name: String,
        sendToBitwarden: Bool
    ) {
        let dismissAction = DismissAction(action: { [weak self] in
            Task {
                await self?.parseAndValidateManualKey(key: key, name: name, sendToBitwarden: sendToBitwarden)
            }
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }

    func parseAndValidateManualKey(key: String, name: String, sendToBitwarden: Bool) async {
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
            let newItem = AuthenticatorItemView(
                favorite: false,
                id: UUID().uuidString,
                name: itemName,
                totpKey: key,
                username: nil
            )
            try await storeNewItem(newItem, sendToBitwarden: sendToBitwarden)
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

    /// Display an alert asking the user if they would like to save their choice as their default save option.
    ///
    /// After handling their answer to this and saving the option to the `AppSettingsStore`, the key will be
    /// processed and handled based on what is passed in `sendToBitwarden`.
    ///
    /// - Parameters:
    ///   - key: The key that was captured
    ///   - sendToBitwarden: `true` if the user previously chose to save the key to the Bitwarden app,
    ///     `false` if they have chosen to store it locally.
    ///
    private func confirmDefaultSaveAlert(key: String, sendToBitwarden: Bool) {
        let title = sendToBitwarden
            ? Localizations.setSaveToBitwardenAsYourDefaultSaveOption
            : Localizations.setSaveLocallyAsYourDefaultSaveOption
        let option: DefaultSaveOption = sendToBitwarden ? .saveToBitwarden : .saveHere

        coordinator.showAlert(.confirmDefaultSaveOption(
            title: title,
            yesAction: { [weak self] in
                self?.services.appSettingsStore.defaultSaveOption = option
                await self?.parseAndValidateAutomaticCaptureKey(key, sendToBitwarden: sendToBitwarden)
            }, noAction: { [weak self] in
                self?.services.appSettingsStore.defaultSaveOption = .none
                await self?.parseAndValidateAutomaticCaptureKey(key, sendToBitwarden: sendToBitwarden)
            }
        ))
    }

    /// Wrap the `parseAndValidateAutomaticCaptureKey` call in a dismiss action so that the coordinator first dismisses
    /// the QR code scan screen and then parses and handles the `key`.
    ///
    /// - Parameters:
    ///   - key: The key that was captured by the QR code scan.
    ///   - sendToBitwarden: `true` if the code should be sent to the Bitwarden app,
    ///     `false` if it should be stored locally.
    /// - Returns: The `DismissAction` to pass to the `.`dismiss` route of the capture coordinator.
    ///
    private func parseKeyAndDismiss(_ key: String, sendToBitwarden: Bool) -> DismissAction {
        DismissAction(action: { [weak self] in
            Task {
                await self?.parseAndValidateAutomaticCaptureKey(key, sendToBitwarden: sendToBitwarden)
            }
        })
    }

    /// Store the new item - either send it to the Bitwarden app (if `sendToBitwarden` is `true`) or
    /// store it locally (if `sendToBitwarden` is `false`)
    ///
    /// - Parameters:
    ///   - newItem: The new `AuthenticatorItemView` that was parsed from a manual or automatic capture.
    ///   - sendToBitwarden: `true` if the item should be sent to the Bitwarden app,
    ///     `false` if it should be stored locally.
    ///
    private func storeNewItem(_ newItem: AuthenticatorItemView, sendToBitwarden: Bool) async throws {
        if sendToBitwarden {
            await moveItemToBitwarden(item: newItem)
        } else {
            try await services.authenticatorItemRepository.addAuthenticatorItem(newItem)
            state.toast = Toast(text: Localizations.verificationCodeAdded)
            await perform(.refresh)
        }
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
