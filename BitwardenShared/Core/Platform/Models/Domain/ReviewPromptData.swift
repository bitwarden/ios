import Foundation

// MARK: - UserActionItem

/// A struct that represents a user action and its count.
struct UserActionItem: Codable, Equatable {
    let userAction: UserAction
    var count: Int
}

// MARK: - ReviewPromptData

/// A struct that combines the version that was last shown the prompt and the user actions.
struct ReviewPromptData: Codable, Equatable {
    /// The app version for which the review prompt has been shown.
    var reviewPromptShownForVersion: String?

    /// The user actions that have been tracked.
    var userActions: [UserActionItem] = []
}

// MARK: - UserAction

/// An enumeration of user actions that can be tracked.
enum UserAction: String, Codable {
    /// The user added a new item.
    case addedNewItem

    /// The user created a new send.
    case createdNewSend

    /// The user copied or inserted a generated value.
    case copiedOrInsertedGeneratedValue
}
