import Foundation

// MARK: - AgentAccessRelayURL

/// Helpers to validate and resolve the relay URL.
///
enum AgentAccessRelayURL {
    /// Whether the string is a `ws://` or `wss://` URL with a host.
    static func isValid(_ url: String) -> Bool {
        guard let components = URLComponents(string: url),
              let scheme = components.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss",
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
