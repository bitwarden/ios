import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - VaultListDirectorStrategy

/// A strategy pattern protocol that defines how vault list sections are built and displayed.
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
/// 2. Transforms the data based on the provided filter
/// 3. Returns a reactive stream of `VaultListData` that updates when underlying data changes
///
/// ## Current Implementations
/// - `MainVaultListDirectorStrategy`: Main vault tab showing all items organized by type
/// - `MainVaultListGroupDirectorStrategy`: Main vault filtered by some `VaultListGroup`
/// - `PasswordsAutofillVaultListDirectorStrategy`: Passwords only Autofill extension vault list view
/// - `CombinedSingleAutofillVaultListDirectorStrategy`: Autofill extension vault list view
/// combining passwords + Fido2 credentials in one section.
/// - `CombinedMultipleAutofillVaultListDirectorStrategy`: Autofill extension vault list view
/// combining passwords + Fido2 credentials in different sections.
/// - `SearchVaultListDirectorStrategy`: Search results for vault list views
/// - `SearchCombinedMultipleAutofillListDirectorStrategy`: Search results for Autofill extension vault list
/// combining passwords + Fido2 credentials in different sections.
///
/// ## Example Usage
/// ```swift
/// let strategy = factory.make(filter: .allVaults)
/// let dataPublisher = try await strategy.build(filter: .allVaults)
///
/// for try await data in dataPublisher {
///     // Update UI with new vault list sections
///     updateSections(data.sections)
/// }
/// ```
///
/// - Note: Strategies are typically struct-based value types with injected dependencies
///   (services, factories) to maintain testability and immutability.
protocol VaultListDirectorStrategy { // sourcery: AutoMockable
    /// Builds the vault list sections.
    /// - Parameters:
    ///   - filter: Filter to be used to build the sections.
    /// - Returns: Vault list data containing the sections to be displayed to the user.
    func build(
        filter: VaultListFilter,
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>
}
