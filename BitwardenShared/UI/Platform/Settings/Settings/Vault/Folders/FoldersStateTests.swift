import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - FoldersStateTests

struct FoldersStateTests {
    // MARK: Tests

    /// `navigationTitle` is "Folders" when the `vfo1-foundation` feature flag is disabled.
    @Test
    func navigationTitle_vfo1FoundationDisabled() {
        let subject = FoldersState(isVfo1FoundationFeatureFlagEnabled: false)

        #expect(subject.navigationTitle == Localizations.folders)
    }

    /// `navigationTitle` is "My folders" when the `vfo1-foundation` feature flag is enabled.
    @Test
    func navigationTitle_vfo1FoundationEnabled() {
        let subject = FoldersState(isVfo1FoundationFeatureFlagEnabled: true)

        #expect(subject.navigationTitle == Localizations.myFolders)
    }
}
