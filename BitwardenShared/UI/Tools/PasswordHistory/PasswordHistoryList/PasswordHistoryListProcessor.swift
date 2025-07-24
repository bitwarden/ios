import BitwardenResources
@preconcurrency import BitwardenSdk
import OSLog

// MARK: - PasswordHistoryListProcessor

/// The processor used to manage state and handle actions for the generator history screen.
///
final class PasswordHistoryListProcessor: StateProcessor<
    PasswordHistoryListState,
    PasswordHistoryListAction,
    PasswordHistoryListEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasGeneratorRepository
        & HasPasteboardService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<PasswordHistoryRoute, Void>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `PasswordHistoryListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<PasswordHistoryRoute, Void>,
        services: Services,
        state: PasswordHistoryListState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PasswordHistoryListEffect) async {
        switch effect {
        case .appeared:
            await streamPasswordHistory()
        case .clearList:
            do {
                try await services.generatorRepository.clearPasswordHistory()
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }

    override func receive(_ action: PasswordHistoryListAction) {
        switch action {
        case let .copyPassword(passwordHistory):
            services.pasteboardService.copy(passwordHistory.password)
            state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.password))
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Stream the generator's password history, if applicable.
    private func streamPasswordHistory() async {
        // If viewing an item's password history, the password history will already
        // be set, so don't load the generator's history.
        if case let .item(passwordHistory) = state.source {
            state.passwordHistory = passwordHistory
            return
        }

        do {
            for try await passwordHistory in try await services.generatorRepository.passwordHistoryPublisher() {
                state.passwordHistory = passwordHistory
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
