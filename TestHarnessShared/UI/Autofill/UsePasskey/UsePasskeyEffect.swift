import Foundation

/// Effects that can be processed by a `UsePasskeyProcessor`.
///
enum UsePasskeyEffect: Equatable {
    /// The user tapped the Sign In with Passkey button.
    case assertPasskey
}
