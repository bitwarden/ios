// MARK: - CipherOwner

/// A type to describe the owner of a cipher.
///
struct CipherOwner: Menuable {
    // MARK: Types

    /// The type of owner.
    enum OwnerType: Equatable, Hashable {
        /// The cipher is owned by an organization.
        case organization(id: String, name: String)

        /// The cipher is owned by the user.
        case personal(email: String)

        /// Whether the owner of the cipher is a personal account.
        var isPersonal: Bool {
            guard case .personal = self else { return false }
            return true
        }

        /// The organization ID of the organization if the owner type is an organization.
        var organizationId: String? {
            guard case let .organization(organizationId, _) = self else { return nil }
            return organizationId
        }
    }

    // MARK: Properties

    /// The type of owner.
    let ownerType: OwnerType

    // MARK: Computed Properties

    var localizedName: String {
        switch ownerType {
        case let .organization(_, name):
            name
        case let .personal(email):
            email
        }
    }
}

extension CipherOwner {
    /// Initializes a `CipherOwner` for an organization owned cipher.
    ///
    /// - Parameters:
    ///   - id: The organization's ID.
    ///   - name: The organization's name.
    /// - Returns: An organization `CipherOwner`.
    ///
    static func organization(id: String, name: String) -> CipherOwner {
        CipherOwner(ownerType: .organization(id: id, name: name))
    }

    /// Initializes a `CipherOwner` for a personally owned cipher.
    ///
    /// - Parameter email: The email of the account that owns the cipher.
    /// - Returns: A personal `CipherOwner`.
    ///
    static func personal(email: String) -> CipherOwner {
        CipherOwner(ownerType: .personal(email: email))
    }
}
