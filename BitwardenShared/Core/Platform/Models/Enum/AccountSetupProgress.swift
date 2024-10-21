// MARK: - AccountSetupProgress

/// An enum to represent a user's progress towards setting up new account functionality.
///
enum AccountSetupProgress: Int, Codable {
    /// The user hasn't yet made any progress.
    case incomplete = 0

    /// The user choose to set up the functionality later.
    case setUpLater = 1

    /// The user has completed the set up.
    case complete = 2
}

extension AccountSetupProgress {
    /// Whether the progress is `.complete`.
    var isComplete: Bool {
        guard case .complete = self else { return false }
        return true
    }
}
