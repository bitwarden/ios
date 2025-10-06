import BitwardenKit

extension HasTOTPCodesSections where Item == ItemListItem, Section == ItemListSection {
    func refreshTOTPCodes(
        for items: [ItemListItem],
        in sections: [ItemListSection],
        using manager: TOTPExpirationManager?
    ) async throws -> [ItemListSection] {
        let updated = try await refreshTOTPCodes(for: items, in: sections)
        manager?.configureTOTPRefreshScheduling(for: updated.flatMap(\.items))
        return updated
    }
}
