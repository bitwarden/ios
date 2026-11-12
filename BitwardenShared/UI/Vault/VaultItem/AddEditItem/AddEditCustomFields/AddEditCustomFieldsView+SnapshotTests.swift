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
    func test_snapshot_allFields() {
        processor.state = AddEditCustomFieldsState(
            cipherType: .identity,
            customFields: [
                CustomFieldState(
                    linkedIdType: nil,
                    name: "Custom text",
                    type: .text,
                    value: "value goes here",
                ),
                CustomFieldState(
                    linkedIdType: nil,
                    name: "Custom text",
                    type: .hidden,
                    value: "value goes here",
                ),
                CustomFieldState(
                    linkedIdType: nil,
                    name: "Custom boolean",
                    type: .boolean,
                ),
                CustomFieldState(
                    linkedIdType: .identityFirstName,
                    name: "Custom linked field",
                    type: .linked,
                ),
            ],
        )
        let view = subject
            .padding(16)
            .background(
                SharedAsset.Colors.backgroundPrimary.swiftUIColor
                    .ignoresSafeArea(),
            )
        assertSnapshots(
            of: view,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }
}
