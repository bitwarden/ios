// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceManagementViewTests

class DeviceManagementViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<DeviceManagementState, DeviceManagementAction, DeviceManagementEffect>!
    var subject: DeviceManagementView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: DeviceManagementState())
        subject = DeviceManagementView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel toolbar button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping a device row with a pending request dispatches the `.deviceTapped` action.
    @MainActor
    func test_deviceRow_tap_withPendingRequest() throws {
        let request = LoginRequest.fixture()
        var device = DeviceListItem.fixture(id: "device-1")
        device.pendingRequest = request
        processor.state.loadingState = .data([device])

        let button = try subject.inspect().find(viewWithAccessibilityIdentifier: "DeviceRowCell")
        try button.button().tap()

        XCTAssertEqual(processor.dispatchedActions.last, .deviceTapped(device))
    }
}
