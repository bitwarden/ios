// MARK: - CipherOwner

/// A type to describe the owner of a cipher.
///
enum CipherOwner: Equatable, Hashable, Menuable {
    /// The cipher is owned by an organization.
    case organization(id: String, name: String)

    /// The cipher is owned by the user.
    case personal(email: String)

    /// Whether the owner of the cipher is a personal account.
    var isPersonal: Bool {
        guard case .personal = self else { return false }
        return true
    }

    var localizedName: String {
        switch self {
        case let .organization(_, name):
            name
        case let .personal(email):
            email
        }
    }

    /// The organization ID of the organization if the owner type is an organization.
    var organizationId: String? {
        guard case let .organization(organizationId, _) = self else { return nil }
        return organizationId
    }
}
