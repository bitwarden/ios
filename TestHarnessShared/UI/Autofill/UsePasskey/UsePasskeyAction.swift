import Foundation

/// Actions that can be processed by a `UsePasskeyProcessor`.
///
enum UsePasskeyAction: Equatable {
    /// The passkey error reference sheet's presented state changed.
    case helpSheetPresentedChanged(Bool)

    /// The relying party ID field was updated.
    case rpIdChanged(String)
}
