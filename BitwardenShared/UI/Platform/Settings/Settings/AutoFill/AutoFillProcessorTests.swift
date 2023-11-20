import XCTest

@testable import BitwardenShared

class AutoFillProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: AutoFillProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        subject = AutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: AutoFillState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.toggleCopyTOTPToggle` updates the state.
    func test_receive_toggleCopyTOTPToggle() {
        subject.state.isCopyTOTPToggleOn = false
        subject.receive(.toggleCopyTOTPToggle(true))

        XCTAssertTrue(subject.state.isCopyTOTPToggleOn)
    }
}
