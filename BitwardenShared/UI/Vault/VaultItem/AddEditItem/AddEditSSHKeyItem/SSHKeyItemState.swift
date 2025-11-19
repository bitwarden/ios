import BitwardenSdk
import Foundation

// MARK: - SSHKeyItemState

/// The state for an SSH key item.
struct SSHKeyItemState: Equatable, Sendable {
    /// Whether the user has permissions to view the cipher's private key.
    var canViewPrivateKey: Bool = false

    /// The visibility of the private key.
    var isPrivateKeyVisible: Bool = false

    /// The private key of the SSH key.
    var privateKey: String = ""

    /// The public key of the SSH key.
    var publicKey: String = ""

    /// The fingerprint of the SSH key.
    var keyFingerprint: String = ""

    /// Gets the `SshKeyView` from this state.
    var sshKeyView: SshKeyView {
        SshKeyView(
            privateKey: privateKey,
            publicKey: publicKey,
            fingerprint: keyFingerprint,
        )
    }
}
