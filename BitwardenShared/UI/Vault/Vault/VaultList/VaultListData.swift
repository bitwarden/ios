import BitwardenSdk

/// A struct containing the data necessary for building the vault list. This contains the list of
/// sections to display along with any additional properties needed from the repository to render
/// the list of items in the vault.
///
public struct VaultListData: Equatable, Sendable {
    // MARK: Properties

    /// A list of cipher IDs for ciphers which failed to decrypt.
    var cipherDecryptionFailureIds = [Uuid]()

    /// The list of sections to display in the vault.
    var sections = [VaultListSection]()
}
