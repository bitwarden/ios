import Foundation

/// Actions that can be processed by a `PasskeyScenarioProcessor`.
///
enum PasskeyScenarioAction: Equatable {
    /// The display name field was updated.
    case displayNameChanged(String)

    /// The mode picker selection changed.
    case modeChanged(PasskeyScenarioState.Mode)

    /// The relying party ID field was updated.
    case rpIdChanged(String)

    /// The username field was updated.
    case userNameChanged(String)
}
