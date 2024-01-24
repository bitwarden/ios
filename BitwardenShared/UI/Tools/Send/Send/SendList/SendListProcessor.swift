import BitwardenSdk
import Foundation

// MARK: - SendListProcessor

/// The processor used to manage state and handle actions for the send tab list screen.
///
final class SendListProcessor: StateProcessor<SendListState, SendListAction, SendListEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSendRepository

    // MARK: Private properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SendRoute>

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
        coordinator: AnyCoordinator<SendRoute>,
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
        case .appeared:
            await streamSendList()
        case let .search(text):
            state.searchResults = await searchSends(for: text)
        case .refresh:
            do {
                try await services.sendRepository.fetchSync(isManualRefresh: true)
            } catch {
                // TODO: BIT-1034 Add an error alert
                print("error: \(error)")
            }
        }
    }

    override func receive(_ action: SendListAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem, context: self)
        case .clearInfoUrl:
            state.infoUrl = nil
        case .infoButtonPressed:
            state.infoUrl = ExternalLinksConstants.sendInfo
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .sendListItemRow(rowAction):
            switch rowAction {
            case let .sendListItemPressed(item):
                switch item.itemType {
                case let .send(sendView):
                    coordinator.navigate(to: .editItem(sendView), context: self)
                case .group:
                    // TODO: BIT-1412 Navigate to the group list screen
                    break
                }
            }
        }
    }

    // MARK: Private Methods

    /// Stream the list of sends.
    private func streamSendList() async {
        do {
            for try await sections in try await services.sendRepository.sendListPublisher() {
                state.sections = sections
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Searches the sends using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the sends.
    /// - Returns: An array of `SendListItem`s. If no results can be found, an empty array will be
    ///   returned.
    ///
    private func searchSends(for searchText: String) async -> [SendListItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        do {
            let result = try await services.sendRepository.searchSendPublisher(searchText: searchText)
            for try await sends in result {
                return sends
            }
        } catch {
            services.errorReporter.log(error: error)
        }

        return []
    }
}

// MARK: - SendListProcessor:SendItemDelegate

extension SendListProcessor: SendItemDelegate {
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
}
