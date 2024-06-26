import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

/// Tests for `VaultItemDecorativeImageView`.
///
/// > Warning: Not testing `AsyncImage` cases for now given that we'd need to make some changes
/// and wrap `AsyncImage` in order to intercept the url call and return a fixed image for the tests.
final class VaultItemDecorativeImageViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test that the placeholder image is shown when not showing web icons.
    func test_snapshot_notShowWebIcons() {
        let subject = VaultItemDecorativeImageView(
            item: VaultListItem.fixture(cipherView: .fixture(login: .fixture(uris: [
                LoginUriView(
                    uri: "some",
                    match: .domain,
                    uriChecksum: ""
                ),
            ]))),
            iconBaseURL: .example,
            showWebIcons: false
        )
        assertSnapshot(of: subject, as: .fixedSize())
    }

    /// Test that the placeholder image is shown when login view is nil.
    func test_snapshot_nilLogin() {
        let subject = VaultItemDecorativeImageView(
            item: VaultListItem.fixture(cipherView: .fixture()),
            iconBaseURL: .example,
            showWebIcons: true
        )
        assertSnapshot(of: subject, as: .fixedSize())
    }
}
