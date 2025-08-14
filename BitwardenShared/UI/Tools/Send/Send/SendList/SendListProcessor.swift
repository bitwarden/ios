import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - SendListProcessor

/// The processor used to manage state and handle actions for the send tab list screen.
///
final class SendListProcessor: StateProcessor<SendListState, SendListAction, SendListEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasPasteboardService
        & HasPolicyService
        & HasSendRepository
        & HasVaultRepository

    // MARK: Private properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SendRoute, Void>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `SendListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SendRoute, Void>,
        services: Services,
        state: SendListState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SendListEffect) async {
        switch effect {
        case let .addItemPressed(sendType):
            await addNewSend(sendType: sendType)
        case .loadData:
            await loadData()
        case let .search(text):
            await searchSends(for: text)
        case .refresh:
            await refresh()
        case let .sendListItemRow(effect):
            switch effect {
            case let .copyLinkPressed(sendView):
                guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }
                services.pasteboardService.copy(url.absoluteString)
                state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink))
            case let .deletePressed(sendView):
                let alert = Alert.confirmationDestructive(title: Localizations.areYouSureDeleteSend) { [weak self] in
                    await self?.deleteSend(sendView)
                }
                coordinator.showAlert(alert)
            case let .removePassword(sendView):
                let alert = Alert.confirmationDestructive(
                    title: Localizations.areYouSureRemoveSendPassword,
                    destructiveTitle: Localizations.remove
                ) { [weak self] in
                    await self?.removePassword(sendView)
                }
                coordinator.showAlert(alert)
            case let .shareLinkPressed(sendView):
                guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }
                coordinator.navigate(to: .share(url: url))
            }
        case .streamSendList:
            await streamSendList()
        }
    }

    override func receive(_ action: SendListAction) {
        switch action {
        case .clearInfoUrl:
            state.infoUrl = nil
        case .infoButtonPressed:
            state.infoUrl = ExternalLinksConstants.sendInfo
        case let .searchStateChanged(isSearching):
            if !isSearching {
                state.searchText = ""
                state.searchResults = []
            }
            state.isSearching = isSearching
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .sendListItemRow(rowAction):
            switch rowAction {
            case let .editPressed(sendView):
                coordinator.navigate(to: .editItem(sendView), context: self)
            case let .sendListItemPressed(item):
                switch item.itemType {
                case let .send(sendView):
                    coordinator.navigate(to: .viewItem(sendView), context: self)
                case let .group(type, _):
                    coordinator.navigate(to: .group(type))
                }
            case let .viewSend(sendView):
                coordinator.navigate(to: .viewItem(sendView), context: self)
            }
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private Methods

    /// Navigates to the add new send view. If the user is trying to add a new send type which
    /// requires premium and they don't have premium this will instead show an error alert to the
    /// user.
    ///
    /// - Parameter sendType: The type of send the user is trying to add.
    ///
    private func addNewSend(sendType: SendType) async {
        if sendType.requiresPremium {
            let hasPremium = await services.sendRepository.doesActiveAccountHavePremium()

            guard hasPremium else {
                coordinator.showAlert(.defaultAlert(title: Localizations.sendFilePremiumRequired))
                return
            }
        }
        coordinator.navigate(to: .addItem(type: sendType), context: self)
    }

    /// Refreshes the user's vault, including sends.
    ///
    private func refresh() async {
        do {
            try await services.sendRepository.fetchSync(forceSync: false, isPeriodic: false)
        } catch {
            await coordinator.showErrorAlert(error: error) {
                await self.refresh()
            }
        }
    }

    /// Deletes the provided send.
    ///
    /// - Parameter sendView: The send to delete.
    ///
    private func deleteSend(_ sendView: SendView) async {
        coordinator.showLoadingOverlay(title: Localizations.deleting)
        do {
            try await services.sendRepository.deleteSend(sendView)
            coordinator.hideLoadingOverlay()
            state.toast = Toast(title: Localizations.sendDeleted)
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error) {
                await self.deleteSend(sendView)
            }
        }
    }

    /// Load any initial data for the view.
    ///
    private func loadData() async {
        state.isSendDisabled = await services.policyService.policyAppliesToUser(.disableSend)
    }

    /// Removes the password from the provided send.
    ///
    /// - Parameter sendView: The send to remove the password from.
    ///
    private func removePassword(_ sendView: SendView) async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.removingSendPassword))
        do {
            _ = try await services.sendRepository.removePassword(from: sendView)
            coordinator.hideLoadingOverlay()
            state.toast = Toast(title: Localizations.sendPasswordRemoved)
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error) {
                await self.removePassword(sendView)
            }
        }
    }

    /// Stream the list of sends.
    ///
    private func streamSendList() async {
        do {
            if let type = state.type {
                for try await sends in try await services.sendRepository.sendTypeListPublisher(type: type) {
                    if sends.isEmpty {
                        state.loadingState = .data([])
                    } else {
                        state.loadingState = .data([
                            SendListSection(
                                id: type.localizedName,
                                items: sends,
                                name: Localizations.sends
                            ),
                        ])
                    }
                }
            } else {
                for try await sections in try await services.sendRepository.sendListPublisher() {
                    let needsSync = try await services.vaultRepository.needsSync()

                    if needsSync, sections.isEmpty {
                        // If a sync is needed and there are no sends in the user's vault, it could
                        // mean the initial sync hasn't completed so sync first.
                        do {
                            try await services.sendRepository.fetchSync(forceSync: false, isPeriodic: true)
                            state.loadingState = .data(sections)
                        } catch {
                            services.errorReporter.log(error: error)
                        }
                    } else {
                        state.loadingState = .data(sections)
                    }
                }
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Searches the sends using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the sends.
    ///
    private func searchSends(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.searchResults = []
            return
        }

        do {
            let result = try await services.sendRepository.searchSendPublisher(
                searchText: searchText,
                type: state.type
            )
            for try await sends in result {
                state.searchResults = sends
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - SendListProcessor:SendItemDelegate

extension SendListProcessor: SendItemDelegate {
    func handle(_ authAction: AuthAction) async {
        // No-Op, only for use by the AppCoordinator.
    }

    func sendItemCancelled() {
        coordinator.navigate(to: .dismiss())
    }

    func sendItemCompleted(with sendView: SendView) {
        Task {
            guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }
            coordinator.navigate(to: .dismiss(DismissAction(action: {
                self.coordinator.navigate(to: .share(url: url))
            })))
        }
    }

    func sendItemDeleted() {
        coordinator.navigate(to: .dismiss(nil))
        state.toast = Toast(title: Localizations.sendDeleted)
    }
}
