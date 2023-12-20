import XCTest

@testable import BitwardenShared

final class ManualEntryProcessorTests: BitwardenTestCase {
    var coordinator: MockCoordinator<AuthenticatorKeyCaptureRoute>!
    var subject: ManualEntryProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        subject = ManualEntryProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(),
            state: DefaultEntryState(deviceSupportsCamera: true)
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    /// `receive()` with `.addPressed(:)` navigates to `.addManual(:)`.
    func test_receive_addPressed() async {
        subject.receive(.addPressed(code: "YouNeedUniqueNewYork"))
        XCTAssertEqual(coordinator.routes, [.addManual(entry: "YouNeedUniqueNewYork")])
    }

    /// `receive()` with `.authenticatorKeyChanged(:)` updates the state.
    func test_receive_authenticatorKeyChanged() async {
        subject.receive(.authenticatorKeyChanged("YouNeedUniqueNewYork"))
        XCTAssertEqual(subject.state.authenticatorKey, "YouNeedUniqueNewYork")
    }

    /// `receive()` with `.dismissPressed` navigates to dismiss.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes, [.dismiss()])
    }

    /// `receive()` with `.scanCodePressed` navigates to `.scanCode`.
    func test_receive_scanCodePressed() async {
        subject.receive(.scanCodePressed)
        XCTAssertEqual(coordinator.routes, [.screen(.scan)])
    }
}
