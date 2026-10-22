// MARK: - AgentAccessPairingEffect

/// Effects that can be processed by an `AgentAccessPairingProcessor`.
///
enum AgentAccessPairingEffect: Equatable {
    /// Create the token or code.
    case startPairing

    /// Start listening for pairing events.
    case streamEvents
}
