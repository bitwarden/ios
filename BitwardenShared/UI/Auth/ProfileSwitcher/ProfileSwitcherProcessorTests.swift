import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherProcessorTests

class ProfileSwitcherProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<ProfileSwitcherRoute, Void>!
    var handler: MockProfileSwitcherHandler!
    var subject: ProfileSwitcherProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        handler = MockProfileSwitcherHandler()
        handler.profileSwitcherState = .singleAccount

        let services = ServiceContainer.withMocks()

        subject = ProfileSwitcherProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            handler: handler,
            services: services,
            state: ProfileSwitcherState.empty(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        handler = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(action:)` passes the action to the handler.
    @MainActor
    func test_receive() throws {
        guard #available(iOS 26, *) else {
            throw XCTSkip("This test requires iOS 26")
        }
        handler.profileSwitcherState.isVisible = true
        subject.receive(.dismissTapped)
        XCTAssertTrue(handler.handleProfileSwitcherActionCalled)
        XCTAssertEqual(handler.handleProfileSwitcherActionReceivedAction, .dismissTapped)
    }

    /// `perform(effect:)` passes the effect to the handler.
    @MainActor
    func test_perform() async {
        await subject.perform(.addAccountPressed)
        XCTAssertTrue(handler.handleProfileSwitcherEffectCalled)
        XCTAssertEqual(handler.handleProfileSwitcherEffectReceivedEffect, .addAccountPressed)
    }
}
