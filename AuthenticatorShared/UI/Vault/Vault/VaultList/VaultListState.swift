import Foundation

// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    /// The url to open in the device's web browser.
    var url: URL?
}
