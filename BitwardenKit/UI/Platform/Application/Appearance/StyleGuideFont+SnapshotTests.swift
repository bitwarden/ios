// swiftlint:disable:this file_name
import SnapshotTesting
import XCTest

@testable import BitwardenKit

final class StyleGuideFontTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the StyleGuideFonts.
    func disabletest_snapshot_styleGuideFont() {
        for preview in StyleGuideFont_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortrait],
            )
        }
    }

    /// Test a snapshot of the StyleGuideFonts with large text.
    func disabletest_snapshot_styleGuideFont_largeText() {
        for preview in StyleGuideFont_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortraitAX5],
            )
        }
    }
}
