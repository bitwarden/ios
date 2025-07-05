import BitwardenSdk

extension CipherListView {
    /// Whether the cipher passes the `.restrictItemTypes` policy based on the organizations restricted.
    ///
    /// - Parameters:
    ///  - cipher: The cipher to check against the policy.
    ///  - restrictItemTypesOrgIds: The list of organization IDs that are restricted by the policy.
    ///  - Returns: `true` if the cipher is allowed by the policy, `false` otherwise.
    ///
    func passesRestrictItemTypesPolicy(_ restrictItemTypesOrgIds: [String]) -> Bool {
        guard !restrictItemTypesOrgIds.isEmpty, type.isCard else {
            return true
        }
        guard let orgId = organizationId, !orgId.isEmpty else {
            return false
        }
        return !restrictItemTypesOrgIds.contains(orgId)
    }
}
