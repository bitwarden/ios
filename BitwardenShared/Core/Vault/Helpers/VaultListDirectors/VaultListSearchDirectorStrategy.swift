import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - VaultListSearchDirectorStrategy

/// A strategy pattern protocol that defines how vault search list sections are built and displayed.
///
/// ## Overview
/// Each conforming strategy encapsulates the logic for building vault list sections for a specific
/// context or view in the app. The strategy determines:
/// - Which data sources to observe (ciphers, collections, folders)
/// - How to filter and transform that data
/// - What sections and items to display
///
/// ## Architecture
/// Strategies are created by `VaultListDirectorStrategyFactory` and typically have a one-to-one
/// relationship with vault list views. Each strategy:
/// 1. Subscribes to relevant data publishers (ciphers, collections, folders)
/// 2. Transforms the data based on the provided filter. In this case the filter is a publisher so the implementation
/// needs to subscribe to its changes.
/// 3. Returns a reactive stream of `VaultListData` that updates when underlying data changes
///
/// ## Current Implementations
/// - `SearchVaultListDirectorStrategy`: Search results for vault list views
/// - `SearchCombinedMultipleAutofillListDirectorStrategy`: Search results for Autofill extension vault list
/// combining passwords + Fido2 credentials in different sections.
///
/// ## Example Usage
/// ```swift
/// let strategy = factory.makeSearchStrategy(mode: .all)
/// let dataPublisher = try await strategy.build(filterPublisher: myFilterPublisher)
///
/// for try await data in dataPublisher {
///     // Update UI with new vault list sections
///     updateSections(data.sections)
/// }
/// ```
///
/// - Note: Strategies are typically struct-based value types with injected dependencies
///   (services, factories) to maintain testability and immutability.
protocol VaultListSearchDirectorStrategy { // sourcery: AutoMockable
    /// Builds the vault list sections.
    /// - Parameters:
    ///   - filterPublisher: Filter publisher to be subscribed to changes to build the sections.
    /// - Returns: Vault list data containing the sections to be displayed to the user.
    func build(
        filterPublisher: AnyPublisher<VaultListFilter, Error>,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>
}
