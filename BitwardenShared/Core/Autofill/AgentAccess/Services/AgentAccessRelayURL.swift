import Foundation

// MARK: - AgentAccessRelayURL

/// Helpers to validate and resolve the relay URL.
///
enum AgentAccessRelayURL {
    /// Whether plain `ws://` URLs are accepted. Only debug builds allow them, for a local relay.
    static var allowsInsecure: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// Whether the string is a `wss://` URL with a host, or a `ws://` URL when insecure URLs are allowed.
    ///
    /// - Parameters:
    ///   - url: The string to check.
    ///   - allowsInsecure: Whether plain `ws://` URLs are accepted.
    ///
    static func isValid(_ url: String, allowsInsecure: Bool = AgentAccessRelayURL.allowsInsecure) -> Bool {
        guard let components = URLComponents(string: url),
              let scheme = components.scheme?.lowercased(),
              scheme == "wss" || (allowsInsecure && scheme == "ws"),
              let host = components.host,
              !host.isEmpty else {
            return false
        }
        return true
    }

    /// Resolves the relay URL: the stored URL, then (debug builds only) the environment override,
    /// then the default.
    static func resolve(stored: String?, environment: [String: String]) -> String {
        if let stored, isValid(stored) {
            return stored
        }
        #if DEBUG
        if let override = environment[AgentAccessConstants.debugRelayURLEnvironmentKey], isValid(override) {
            return override
        }
        #endif
        return AgentAccessConstants.defaultRelayURL
    }
}
