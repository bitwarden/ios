import Foundation

// MARK: - E2ETimeouts

/// Every timeout used by the end-to-end suite.
///
enum E2ETimeouts {
    /// How long to wait for an element on a screen that's already shown.
    static let element: TimeInterval = 10

    /// How long to wait for the vault after submitting the master password. Covers key derivation
    /// and the first sync.
    static let login: TimeInterval = 60

    /// How long to wait for a screen to appear after a navigation.
    static let screen: TimeInterval = 15

    /// How long a seeder request may take.
    static let seederRequest: TimeInterval = 60
}
