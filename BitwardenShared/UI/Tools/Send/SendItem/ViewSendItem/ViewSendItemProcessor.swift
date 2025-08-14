import BitwardenResources

// MARK: - ViewSendItemProcessor

/// The processor used to manage state and handle actions for the view send item screen.
///
class ViewSendItemProcessor: StateProcessor<ViewSendItemState, ViewSendItemAction, ViewSendItemEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasSendRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation for this processor.
    private let coordinator: AnyCoordinator<SendItemRoute, AuthAction>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ViewSendItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation for this processor.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<SendItemRoute, AuthAction>,
        services: Services,
        state: ViewSendItemState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewSendItemEffect) async {
        switch effect {
        case .deleteSend:
            coordinator.showAlert(.confirmationDestructive(title: Localizations.areYouSureDeleteSend) {
                await self.deleteSend()
            })
        case .loadData:
            await loadData()
        case .streamSend:
            await streamSend()
        }
    }

    override func receive(_ action: ViewSendItemAction) {
        switch action {
        case .copyNotes:
            guard let notes = state.sendView.notes else { return }
            services.pasteboardService.copy(notes)
            state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.privateNote))
        case .copyShareURL:
            guard let shareURL = state.shareURL else { return }
            services.pasteboardService.copy(shareURL.absoluteString)
            state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink))
        case .dismiss:
            coordinator.navigate(to: .cancel)
        case .editItem:
            coordinator.navigate(to: .edit(state.sendView))
        case .shareSend:
            guard let shareURL = state.shareURL else { return }
            coordinator.navigate(to: .share(url: shareURL))
        case let .toastShown(toast):
            state.toast = toast
        case .toggleAdditionalOptions:
            state.isAdditionalOptionsExpanded.toggle()
        }
    }

    // MARK: Private

    /// Deletes the send.
    ///
    private func deleteSend() async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.deleting))
        do {
            try await services.sendRepository.deleteSend(state.sendView)
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .deleted)
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error) {
                await self.deleteSend()
            }
        }
    }

    /// Loads the data for the view.
    ///
    private func loadData() async {
        do {
            state.shareURL = try await services.sendRepository.shareURL(for: state.sendView)
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Streams the details of the send, so the view updates if the send changes.
    ///
    private func streamSend() async {
        do {
            guard let sendId = state.sendView.id else {
                throw BitwardenError.dataError("View Send: send ID is nil, can't stream updates to send")
            }
            for try await sendView in try await services.sendRepository.sendPublisher(id: sendId) {
                guard let sendView else { return }
                state.sendView = sendView
            }
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
