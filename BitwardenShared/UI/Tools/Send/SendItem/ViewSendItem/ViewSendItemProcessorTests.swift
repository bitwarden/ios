import XCTest

@testable import BitwardenShared

class ViewSendItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendItemRoute, AuthAction>!
    var subject: ViewSendItemProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = ViewSendItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(),
            state: ViewSendItemState(sendView: .fixture())
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismiss` navigates to the cancel route.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .cancel)
    }

    /// `receive(_:)` with `.editItem` navigates to the edit send view.
    @MainActor
    func test_receive_editItem() {
        subject.receive(.editItem)

        XCTAssertEqual(coordinator.routes.last, .edit(subject.state.sendView))
    }
}
