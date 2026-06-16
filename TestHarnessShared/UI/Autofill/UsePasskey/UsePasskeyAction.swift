import Foundation

/// Actions that can be processed by a `UsePasskeyProcessor`.
///
enum UsePasskeyAction: Equatable {
    /// The relying party ID field was updated.
    case rpIdChanged(String)
}
