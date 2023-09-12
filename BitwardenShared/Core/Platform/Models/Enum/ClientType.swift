/// An enum describing a type of client.
///
enum ClientType: Int {
    /// The web client.
    case web = 1

    /// The browser client.
    case browser = 2

    /// The desktop client.
    case desktop = 3

    /// The mobile client.
    case mobile = 4

    /// The CLI client.
    case cli = 5

    /// The directory connector client.
    case directoryConnector = 6

    /// Returns a string representation of the client type.
    var stringValue: String {
        switch self {
        case .browser: return "browser"
        case .cli: return "cli"
        case .desktop: return "desktop"
        case .directoryConnector: return "connector"
        case .mobile: return "mobile"
        case .web: return "web"
        }
    }
}
