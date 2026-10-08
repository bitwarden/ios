import BitwardenSdk

// MARK: - AgentFillApprovalItem

/// An item in the user's vault that can be approved for an agent fill request.
///
struct AgentFillApprovalItem: Equatable, Identifiable, Sendable {
    // MARK: Properties

    /// The ID of the vault item.
    let id: String

    /// The name of the vault item.
    let name: String

    /// The secondary line of the vault item: the username of a login or the details of a card.
    let subtitle: String
}

// MARK: - AgentFillApprovalStatus

/// The status of the approval request shown by the `AgentFillApprovalView`.
///
enum AgentFillApprovalStatus: Equatable, Sendable {
    /// The request couldn't be opened, so it can't be approved.
    case failed

    /// The request was already answered, for example on another device.
    case handled

    /// The request is being fetched and opened.
    case loading

    /// The request is open and waiting for the user's answer.
    case pending

    /// The request has expired.
    case expired
}

// MARK: - AgentFillApprovalState

/// The state used to present the `AgentFillApprovalView`.
///
struct AgentFillApprovalState: Equatable, Sendable {
    // MARK: Properties

    /// The ID of the approval request.
    let approvalId: String

    /// The kind of item the agent wants to fill.
    var cipherType: ApprovalCipherType = .login

    /// The name of the agent connection, such as "Claude Desktop".
    var connectionName = ""

    /// The domain of the tab the agent wants to fill.
    var domain = ""

    /// The name of the browser the agent wants to fill in.
    var browserName = ""

    /// The items the user can approve.
    var items = [AgentFillApprovalItem]()

    /// The ID of the item the user selected.
    var selectedItemId: String?

    /// The status of the request.
    var status = AgentFillApprovalStatus.loading

    // MARK: Computed Properties

    /// Whether the user can approve the request.
    var canApprove: Bool {
        status == .pending && selectedItemId != nil
    }
}
