import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - VaultSettingsStateTests

struct VaultSettingsStateTests {
    // MARK: Tests

    /// `foldersTitle` is "Folders" when the `vfo1-foundation` feature flag is disabled.
    @Test
    func foldersTitle_vfo1FoundationDisabled() {
        let subject = VaultSettingsState(isVfo1FoundationFeatureFlagEnabled: false)

        #expect(subject.foldersTitle == Localizations.folders)
    }

    /// `foldersTitle` is "My folders" when the `vfo1-foundation` feature flag is enabled.
    @Test
    func foldersTitle_vfo1FoundationEnabled() {
        let subject = VaultSettingsState(isVfo1FoundationFeatureFlagEnabled: true)

        #expect(subject.foldersTitle == Localizations.myFolders)
    }
}
