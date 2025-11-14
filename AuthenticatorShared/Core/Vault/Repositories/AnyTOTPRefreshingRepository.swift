import BitwardenKit

/// A struct to allow the use of `AuthenticatorItemRepository` in a generic context.
struct AnyTOTPRefreshingRepository: TOTPRefreshingRepository {
    // MARK: Types

    /// The type os item in the list to be refreshed.
    typealias Item = ItemListItem

    // MARK: Properties

    private let base: AuthenticatorItemRepository

    // MARK: Initialization

    init(_ base: AuthenticatorItemRepository) {
        self.base = base
    }

    // MARK: Methods

    func refreshTotpCodes(for items: [ItemListItem]) async throws -> [ItemListItem] {
        try await base.refreshTotpCodes(for: items)
    }
}
