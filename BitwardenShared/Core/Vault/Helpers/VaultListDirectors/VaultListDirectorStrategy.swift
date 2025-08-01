import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - VaultListDirectorStrategy

/// A protocol for a strategy for a vault list director that determines how the vault list sections are built.
///
/// The strategies conformed by this protocol are built using a `VaultListDirectorStrategyFactory`.
/// Additionally, typically one strategy goes one-to-one with each vault list representation/view.
/// Example: `MainVaultListDirectorStrategy` is used to build the sections in the main vault tab of the app.
protocol VaultListDirectorStrategy { // sourcery: AutoMockable
    /// Builds the vault list sections.
    /// - Parameters:
    ///   - filter: Filter to be used to build the sections.
    /// - Returns: Vault list data containing the sections to be displayed to the user.
    func build(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<VaultListData, Error>>
}
