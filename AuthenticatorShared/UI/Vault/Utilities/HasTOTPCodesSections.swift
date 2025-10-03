/// A protocol to work with processors that have TOTP sections.
@MainActor
protocol HasTOTPCodesSections {
    /// The repository used by the application to manage vault data for the UI layer.
    var authenticatorItemRepository: AuthenticatorItemRepository { get }

    /// Refreshes the TOTP Codes from items in sections using the corresponding manager.
    func refreshTOTPCodes(
        for items: [ItemListItem],
        in sections: [ItemListSection],
        using manager: TOTPExpirationManager?
    ) async throws -> [ItemListSection]
}

/// Extension of the `HasTOTPCodesSections` protocol for some common behavior.
extension HasTOTPCodesSections {
    func refreshTOTPCodes(
        for items: [ItemListItem],
        in sections: [ItemListSection],
        using manager: TOTPExpirationManager?
    ) async throws -> [ItemListSection] {
        let refreshedItems = try await authenticatorItemRepository.refreshTotpCodes(for: items)
        let updatedSections = sections.updated(with: refreshedItems)
        let allItems = updatedSections.flatMap(\.items)
        manager?.configureTOTPRefreshScheduling(for: allItems)
        return updatedSections
    }
}
