import BitwardenKit
import BitwardenResources
import BitwardenSdk

// MARK: - SendAccessType

/// An enum representing the access type options for a Send.
///
enum SendAccessType: CaseIterable, Equatable, Hashable, Menuable, Sendable {
    /// Anyone with the link can view the Send.
    case anyoneWithLink

    /// Only specific people with verified email can view the Send.
    case specificPeople

    /// Anyone with a password set by the sender can view the Send.
    case anyoneWithPassword

    // MARK: Properties

    /// The SDK `AuthType` corresponding to this access type.
    var authType: AuthType {
        switch self {
        case .anyoneWithLink:
            .none
        case .specificPeople:
            .email
        case .anyoneWithPassword:
            .password
        }
    }

    var localizedName: String {
        switch self {
        case .anyoneWithLink:
            Localizations.anyoneWithTheLink
        case .specificPeople:
            Localizations.specificPeople
        case .anyoneWithPassword:
            Localizations.anyoneWithPasswordSetByYou
        }
    }

    // MARK: Initialization

    /// Creates a `SendAccessType` from the SDK's `AuthType`.
    ///
    /// - Parameter authType: The SDK `AuthType` to convert.
    ///
    init(authType: AuthType) {
        switch authType {
        case .none:
            self = .anyoneWithLink
        case .email:
            self = .specificPeople
        case .password:
            self = .anyoneWithPassword
        }
    }

    /// Creates a `SendAccessType` from the Send Controls policy's `whoCanAccess` value, or `nil`
    /// when the access type is unrestricted.
    ///
    /// The server's `WhoCanAccessType`: `0` = Any (unrestricted), `1` = PasswordProtected,
    /// `2` = SpecificPeople (email verification).
    ///
    /// - Parameter whoCanAccessPolicyValue: The policy's `whoCanAccess` int value.
    ///
    init?(whoCanAccessPolicyValue value: Int?) {
        switch value {
        case 1:
            self = .anyoneWithPassword
        case 2:
            self = .specificPeople
        default:
            return nil
        }
    }
}
