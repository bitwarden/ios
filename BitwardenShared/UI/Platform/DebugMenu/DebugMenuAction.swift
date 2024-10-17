import Foundation

// MARK: - DebugMenuAction

/// Actions that can be processed by a `DebugMenuProcessor`.
///
enum DebugMenuAction: Equatable {
    /// The dismiss button was tapped.
    case dismissTapped
    /// The generate crash button was tapped.
    case generateCrash
    /// The generate error report button was tapped.
    case generateErrorReport
}
