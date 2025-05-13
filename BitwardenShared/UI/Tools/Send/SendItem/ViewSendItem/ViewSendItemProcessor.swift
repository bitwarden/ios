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
        case .loadData:
            await loadData()
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

    /// Loads the data for the view.
    ///
    private func loadData() async {
        do {
            state.shareURL = try await services.sendRepository.shareURL(for: state.sendView)
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
