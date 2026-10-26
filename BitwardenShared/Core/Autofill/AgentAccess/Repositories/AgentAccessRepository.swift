import Combine
import Foundation

// MARK: - AgentAccessRepository

/// The only Agent Access API the UI layer uses. Everything is scoped to the active account.
protocol AgentAccessRepository: AnyObject { // sourcery: AutoMockable
    // MARK: Settings

    /// Whether the `ai-agent-access` feature flag is on.
    func isFeatureEnabled() async -> Bool

    /// Whether the active account is listening for agent requests.
    func isListeningEnabled() async -> Bool

    /// Turns listening on or off for the active account. Turning it on registers the identity with
    /// the server and connects to the relay; turning it off disconnects and unregisters.
    func setListeningEnabled(_ enabled: Bool) async throws

    /// The relay URL for the active account (default `AgentAccessConstants.defaultRelayURL`).
    func relayURL() async -> String

    /// Saves a new relay URL (`wss://` only, plus `ws://` in debug builds) and reconnects.
    func setRelayURL(_ url: String) async throws

    /// Clears the custom relay URL so the default is used, and reconnects.
    func resetRelayURL() async throws

    /// Publishes the connection status of the active account.
    func statusPublisher() -> AnyPublisher<AgentAccessConnectionStatus, Never>

    // MARK: Pairing

    /// Creates a PSK token or rendezvous code. Starts the client if it is not running.
    func createPairing(kind: AgentAccessPairingKind, name: String) async throws -> AgentAccessPairing

    /// Publishes events for the most recent pairing.
    func pairingEventsPublisher() -> AnyPublisher<AgentAccessPairingEvent, Never>

    /// Answers a rendezvous fingerprint comparison.
    func answerFingerprintVerification(id: String, approved: Bool)

    // MARK: Connections

    func connections() async throws -> [AgentAccessConnection]

    /// Deletes the connection, drops its auto-approve rules, denies its pending requests, restarts the
    /// client so cached transport state is evicted, and writes a `connectionRevoked` audit entry.
    func revokeConnection(fingerprint: String) async throws

    // MARK: Approvals

    /// Publishes the pending approval requests, oldest first. Empty when none.
    func pendingRequestsPublisher() -> AnyPublisher<[AgentAccessApprovalRequest], Never>

    func pendingRequest(id: String) async -> AgentAccessApprovalRequest?

    /// Vault logins the user can pick for this request (non-deleted, non-archived, no master password
    /// reprompt). `.domain` and `.search` match the way AI-136 does; `.id` returns the single item.
    func candidates(for requestId: String) async throws -> [AgentAccessCandidate]

    /// Delivers the decision to the SDK callback. The caller (UI) has already verified the user
    /// (biometrics or master password) before an `.approve`.
    /// - Throws: `.requestExpired` if the 110 s window passed, `.cipherNotFound`.
    func answer(requestId: String, decision: AgentAccessDecision) async throws

    func autoApproveRules() async -> [AgentAccessAutoApproveRule]

    func removeAutoApproveRule(id: String) async

    // MARK: Audit

    /// Newest first, at most `AgentAccessConstants.maxAuditEntries`.
    func auditLog() async throws -> [AgentAccessAuditEntry]

    func clearAuditLog() async throws

    // MARK: Lifecycle (called by AppProcessor and NotificationService, not by the UI)

    /// App became active or launched: start the client for the active account if listening is enabled
    /// and the flag is on; re-register the identity with the server.
    func appDidBecomeActive() async

    /// App entered the background: stop the client, except while a pairing is pending (then keep it
    /// for the OS background grace period).
    func appDidEnterBackground() async

    /// The active account changed (or logged out): stop the old client, start for the new account.
    func activeAccountChanged(userId: String?) async

    /// A push or local notification for this account was tapped: switch is done by the caller,
    /// this starts the client so buffered requests are delivered.
    func notificationTapped(userId: String) async
}
