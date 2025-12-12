import BitwardenKit
import Combine

// MARK: - SearchProcessorMediator

/// A protocol for a mediator between processors and search publisher/subscription behavior.
protocol SearchProcessorMediator { // sourcery: AutoMockable
    /// Event that happens when a filter changes so the search results should be updated.
    /// - Parameter filter: The new filter.
    func onFilterChanged(_ filter: VaultListFilter)
    /// Sets the `AutofillListMode` to use in the search.
    /// - Parameter mode: The mode to use in the search.
    func setAutofillListMode(_ mode: AutofillListMode)
    /// Sets the delegate to make updates to the caller.
    /// - Parameter delegate: The delegate to set.
    func setDelegate(_ delegate: SearchProcessorMediatorDelegate)
    /// Starts the searching process.
    func startSearching()
    /// Stops the searching process.
    func stopSearching()
}

// MARK: - SearchProcessorMediatorDelegate

/// A delegate to be used by the `SearchProcessorMediator` to report back to the caller processor.
@MainActor
protocol SearchProcessorMediatorDelegate: AnyObject { // sourcery: AutoMockable
    /// This gets executed every time new search results arrive to update the caller processor with them.
    /// - Parameter data: The new search results data.
    func onNewSearchResults(data: VaultListData)
}

// MARK: - DefaultSearchProcessorMediator

/// The default implementation of `SearchProcessorMediator`.
class DefaultSearchProcessorMediator: SearchProcessorMediator {
    // MARK: Properties

    /// The autofill list mode the caller processor is in, if any.
    private var autofillListMode: AutofillListMode?

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The delegate to use by this mediator to report back to the caller processor.
    private weak var searchProcessorMediatorDelegate: SearchProcessorMediatorDelegate?

    /// Publisher for the current vault list filter. Emits new filter values when search criteria changes.
    private let vaultListFilterSubject = PassthroughSubject<VaultListFilter, Never>()

    /// Cancellable for the vault list subscription
    private var vaultListSubscription: AnyCancellable?

    /// The repository used by the application to manage vault data for the UI layer.
    private let vaultRepository: VaultRepository

    /// The task that has the search list publisher subscription.
    private var vaultSearchListSubscriptionTask: Task<Void, Never>?

    // MARK: Computed properties

    /// Publisher that emits when the vault list filter changes (e.g., search text updates)
    var vaultListFilterPublisher: AnyPublisher<VaultListFilter, Error> {
        vaultListFilterSubject
            .setFailureType(to: Error.self)
            .removeDuplicates() // Prevent duplicate emissions if same filter sent twice
            .eraseToAnyPublisher()
    }

    /// Initializes a `DefaultSearchProcessorMediator`.
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    init(
        errorReporter: ErrorReporter,
        vaultRepository: VaultRepository,
    ) {
        self.errorReporter = errorReporter
        self.vaultRepository = vaultRepository
    }

    /// Deinitializes this processor mediator.
    deinit {
        vaultSearchListSubscriptionTask?.cancel()
        vaultSearchListSubscriptionTask = nil
        searchProcessorMediatorDelegate = nil
    }

    // MARK: Methods

    func onFilterChanged(_ filter: VaultListFilter) {
        vaultListFilterSubject.send(filter)
    }

    func setAutofillListMode(_ mode: AutofillListMode) {
        autofillListMode = mode
    }

    func setDelegate(_ delegate: SearchProcessorMediatorDelegate) {
        searchProcessorMediatorDelegate = delegate
    }

    func startSearching() {
        vaultSearchListSubscriptionTask?.cancel()
        vaultSearchListSubscriptionTask = Task { [weak self] in
            guard let self else { return }

            do {
                let publisher = try await vaultRepository.vaultSearchListPublisher(
                    mode: autofillListMode,
                    filterPublisher: vaultListFilterPublisher,
                )

                for try await vaultListData in publisher {
                    guard !Task.isCancelled else { break }

                    await searchProcessorMediatorDelegate?.onNewSearchResults(data: vaultListData)
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    func stopSearching() {
        vaultSearchListSubscriptionTask?.cancel()
    }
}

// MARK: - SearchProcessorMediatorFactory

/// A factory protocol to make `SearchProcessorMediator`s.
protocol SearchProcessorMediatorFactory { // sourcery: AutoMockable
    /// Makes a new `SearchProcessorMediator`.
    /// - Returns: A `SearchProcessorMediator`.
    func make() -> SearchProcessorMediator
}

// MARK: - DefaultSearchProcessorMediatorFactory

/// The default implementation of `SearchProcessorMediatorFactory`.
class DefaultSearchProcessorMediatorFactory: SearchProcessorMediatorFactory {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The repository used by the application to manage vault data for the UI layer.
    private let vaultRepository: VaultRepository

    /// Initializes a `DefaultSearchProcessorMediatorFactory`.
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    init(errorReporter: ErrorReporter, vaultRepository: VaultRepository) {
        self.errorReporter = errorReporter
        self.vaultRepository = vaultRepository
    }

    // MARK: Methods

    func make() -> SearchProcessorMediator {
        DefaultSearchProcessorMediator(
            errorReporter: errorReporter,
            vaultRepository: vaultRepository,
        )
    }
}
