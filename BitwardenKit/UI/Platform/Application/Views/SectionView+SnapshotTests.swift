// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenKit

class SectionViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of a section view containing a text field.
    @MainActor
    func test_snapshot_sectionView() {
        let subject = VStack {
            SectionView("Section View") {
                BitwardenTextField(title: Localizations.name, text: .constant("name"))
            }
        }
        .padding(16)
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)

        assertSnapshots(of: subject, as: [.defaultPortrait])
    }
}
