// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AddEditCustomFieldsViewTests

class AddEditCustomFieldsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditCustomFieldsState, AddEditCustomFieldsAction, Void>!
    var subject: AddEditCustomFieldsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: .init(
                cipherType: .login,
                customFields: [.init(name: "custom1", type: .text)],
            ),
        )
        let store = Store(processor: processor)
        subject = AddEditCustomFieldsView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The view with all types of custom fields renders correctly.
    @MainActor
    func disabletest_snapshot_allFields() {
        for preview in AddEditCustomFieldsView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultPortraitDark,
                    .defaultPortraitAX5,
                ],
            )
        }
    }
}
