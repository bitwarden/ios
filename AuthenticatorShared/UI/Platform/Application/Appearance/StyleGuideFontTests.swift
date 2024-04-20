import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

final class StyleGuideFontTests: AuthenticatorTestCase {
    // MARK: Tests

    /// Test a snapshot of the StyleGuideFonts.
    func test_snapshot_styleGuideFont() {
        for preview in StyleGuideFont_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortrait]
            )
        }
    }

    /// Test a snapshot of the StyleGuideFonts with large text.
    func test_snapshot_styleGuideFont_largeText() {
        for preview in StyleGuideFont_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortraitAX5]
            )
        }
    }
}
