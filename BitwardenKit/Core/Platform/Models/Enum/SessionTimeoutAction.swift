import BitwardenResources

/// The action to perform on session timeout.
///
public enum SessionTimeoutAction: Int, CaseIterable, Codable, Equatable, Menuable, Sendable {
    /// Lock the vault.
    case lock = 0

    /// Log the user out.
    case logout = 1

    /// All of the cases to show in the menu.
    public static let allCases: [SessionTimeoutAction] = [.lock, .logout]

    public var localizedName: String {
        switch self {
        case .lock:
            Localizations.lock
        case .logout:
            Localizations.logOut
        }
    }
}
