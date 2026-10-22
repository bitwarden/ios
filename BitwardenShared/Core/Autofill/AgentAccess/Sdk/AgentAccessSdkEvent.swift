import Foundation

// MARK: - AgentAccessSdkEvent

/// A status event emitted by the SDK client.
///
enum AgentAccessSdkEvent: Equatable, Sendable {
    case connecting
    case connected
    case listening
    case disconnected
    case reconnecting
    case reconnected
    case error(message: String)
    case other
}
