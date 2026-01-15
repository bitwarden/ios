import BitwardenKit
import Combine

// MARK: - SearchProcessorMediator

/// A protocol for a mediator between processors and search publisher/subscription behavior.
protocol SearchProcessorMediator { // sourcery: AutoMockable
    /// Starts the searching process.
    /// - Parameters:
    ///   - mode: The `AutofillListMode` to use in searching, if any.
    ///   - onNewSearchResults: A closure that gets called when new search results arrive.
    func startSearching(mode: AutofillListMode?, onNewSearchResults: @escaping (VaultListData) async -> Void)
    /// Stops the searching process.
    func stopSearching()
    /// Updates the filter so the search results should be updated.
    /// - Parameter filter: The new filter.
    func updateFilter(_ filter: VaultListFilter)
}

// MARK: - DefaultSearchProcessorMediator

/// The default implementation of `SearchProcessorMediator`.
class DefaultSearchProcessorMediator: SearchProcessorMediator {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

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
    }

    // MARK: Methods

    func startSearching(mode: AutofillListMode?, onNewSearchResults: @escaping (VaultListData) async -> Void) {
        vaultSearchListSubscriptionTask?.cancel()
        vaultSearchListSubscriptionTask = Task { [weak self, vaultListFilterPublisher] in
            do {
                let publisher = try await self?.vaultRepository.vaultSearchListPublisher(
                    mode: mode,
                    filterPublisher: vaultListFilterPublisher,
                )
                guard let publisher else { return }

                for try await vaultListData in publisher {
                    guard !Task.isCancelled else { break }

                    await onNewSearchResults(vaultListData)
                }
            } catch {
                self?.errorReporter.log(error: error)
            }
        }
    }

    func stopSearching() {
        vaultSearchListSubscriptionTask?.cancel()
    }

    func updateFilter(_ filter: VaultListFilter) {
        vaultListFilterSubject.send(filter)
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
