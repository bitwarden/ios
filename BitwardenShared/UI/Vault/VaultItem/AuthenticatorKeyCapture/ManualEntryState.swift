import SwiftUI

// MARK: - ManualEntryState

/// A sendable protocol to represent the state of manually entering an authenticator key.
///
protocol ManualEntryState: Sendable {
    /// The key for this item.
    var authenticatorKey: String { get set }

    /// Does the device support camera.
    var deviceSupportsCamera: Bool { get }
}

struct DefaultEntryState: ManualEntryState {
    var authenticatorKey: String = ""

    var deviceSupportsCamera: Bool
}
