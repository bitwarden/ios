import Foundation

/// Effects that can be processed by a `CreatePasskeyProcessor`.
///
enum CreatePasskeyEffect: Equatable {
    /// The user tapped the Register Passkey button.
    case registerPasskey
}
