// MARK: - LearnNewLoginActionCardStatus

/// An enum to represent the status of the learn new login action card.
///
enum LearnNewLoginActionCardStatus: Int, Codable {
    /// The user is new user and eligible to see the card.
    case eligible

    /// The user has interacted with the card and it is now dismissed.
    case completed
}
