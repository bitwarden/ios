import BitwardenSdk
import Foundation

// MARK: - ItemsProcessor

/// A `Processor` that can process `ItemsAction`s and `ItemsEffect`s.
final class ItemsProcessor: StateProcessor<ItemsState, ItemsAction, ItemsEffect> {
    // MARK: Types

    typealias Services = HasCameraService
        & HasErrorReporter
        & HasItemRepository
        & HasPasteboardService
        & HasTOTPService
        & HasTimeProvider

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private var coordinator: any Coordinator<ItemsRoute, ItemsEvent>

    /// The services for this processor.
    private var services: Services

    /// An object to manage TOTP code expirations and batch refresh calls for the group.
    private var groupTotpExpirationManager: TOTPExpirationManager?

    // MARK: Initialization

    /// Creates a new `ItemsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services for this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<ItemsRoute, ItemsEvent>,
        services: Services,
        state: ItemsState
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

    override func perform(_ effect: ItemsEffect) async {
        switch effect {
        case .addItemPressed:
            await setupTotp()
        case .appeared:
            await streamItemList()
        case .refresh:
            await streamItemList()
        case .streamVaultList:
            await streamItemList()
        }
    }

    override func receive(_ action: ItemsAction) {
        switch action {
        case .clearURL:
            break
        case let .copyTOTPCode(code):
            services.pasteboardService.copy(code)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
        case .itemPressed:
            break
        case .morePressed:
            break
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [VaultListItem]) async {
        guard case .data = state.loadingState else { return }
        do {
            let refreshedItems = try await services.itemRepository.refreshTOTPCodes(for: items)
            groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: refreshedItems)
            state.loadingState = .data(refreshedItems)
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

    /// Stream the items list.
    private func streamItemList() async {
        do {
            for try await vaultList in try await services.itemRepository.vaultListPublisher() {
                groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: vaultList)
                state.loadingState = .data(vaultList)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

/// A class to manage TOTP code expirations for the ItemsProcessor and batch refresh calls.
///
private class TOTPExpirationManager {
    // MARK: Properties

    /// A closure to call on expiration
    ///
    var onExpiration: (([VaultListItem]) -> Void)?

    // MARK: Private Properties

    /// All items managed by the object, grouped by TOTP period.
    ///
    private(set) var itemsByInterval = [UInt32: [VaultListItem]]()

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
        onExpiration: (([VaultListItem]) -> Void)?
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
    func configureTOTPRefreshScheduling(for items: [VaultListItem]) {
        var newItemsByInterval = [UInt32: [VaultListItem]]()
        items.forEach { item in
            guard case let .totp(_, model) = item.itemType else { return }
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
        var expired = [VaultListItem]()
        var notExpired = [UInt32: [VaultListItem]]()
        itemsByInterval.forEach { period, items in
            let sortedItems: [Bool: [VaultListItem]] = TOTPExpirationCalculator.listItemsByExpiration(
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

extension ItemsProcessor: AuthenticatorKeyCaptureDelegate {
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
            let loginTotpState = LoginTOTPState(authKeyModel: authKeyModel)
            let newCipher = CipherView(
                id: UUID().uuidString,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: "Example",
                notes: nil,
                type: .login,
                login: .init(
                    username: nil,
                    password: nil,
                    passwordRevisionDate: nil,
                    uris: nil,
                    totp: loginTotpState.rawAuthenticatorKeyString,
                    autofillOnPageLoad: nil,
                    fido2Credentials: nil
                ),
                identity: nil,
                card: nil,
                secureNote: nil,
                favorite: false,
                reprompt: .none,
                organizationUseTotp: false,
                edit: true,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: .now,
                deletedDate: nil,
                revisionDate: .now
            )
            Task {
                try await services.itemRepository.addItem(newCipher)
                await perform(.refresh)
            }
            state.toast = Toast(text: Localizations.authenticatorKeyAdded)
        } catch {
            // Replace with better alerts later
//            coordinator.navigate(to: .alert(.totpScanFailureAlert()))
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
