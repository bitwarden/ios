import BitwardenSdk
import Foundation

// TODO: PM-30129: remove this file.

/// A helper protocol to centralize archive logic.
protocol CipherWithArchive {
    /// The date the cipher was archived.
    var archivedDate: Date? { get }

    /// The date the cipher was deleted.
    var deletedDate: Date? { get }
}

/// Extension with logic for archive functionality.
extension CipherWithArchive {
    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    /// This is similar to the above `isHidden` property but taking into consideration
    /// the `FeatureFlag.archiveVaultItems` flag.
    ///
    /// TODO: PM-30129 When FF gets removed, replace all calls to this function with the above `isHidden` property
    /// and remove this function.
    ///
    /// - Parameter archiveVaultItemsFeatureFlagEnabled: The `FeatureFlag.archiveVaultItems` flag value.
    /// - Returns: `true` if hidden, `false` otherwise.
    func isHiddenWithArchiveFF(flag archiveVaultItemsFeatureFlagEnabled: Bool) -> Bool {
        if deletedDate != nil {
            return true
        }

        guard archiveVaultItemsFeatureFlagEnabled else {
            return false
        }

        return archivedDate != nil
    }
}

extension Cipher: CipherWithArchive {}
extension CipherListView: CipherWithArchive {}
extension CipherView: CipherWithArchive {}
