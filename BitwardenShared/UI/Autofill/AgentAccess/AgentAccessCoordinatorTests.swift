import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessCoordinatorTests

class AgentAccessCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: AgentAccessCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = AgentAccessCoordinator(
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.approval` replaces the stack with the approval view.
    @MainActor
    func test_navigate_approval() throws {
        subject.navigate(to: .approval(requestId: "request-1"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AgentAccessApprovalView)
    }

    /// `navigate(to:)` with `.auditLog` pushes the activity log.
    @MainActor
    func test_navigate_auditLog() throws {
        subject.navigate(to: .auditLog)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AgentAccessAuditLogView>)
    }

    /// `navigate(to:)` with `.back` pops the current screen.
    @MainActor
    func test_navigate_back() throws {
        subject.navigate(to: .back)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .popped)
    }

    /// `navigate(to:)` with `.connections` pushes the connections.
    @MainActor
    func test_navigate_connections() throws {
        subject.navigate(to: .connections)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AgentAccessConnectionsView>)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the sheet.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` runs the dismiss action.
    @MainActor
    func test_navigate_dismiss_action() throws {
        var actionRan = false
        subject.navigate(to: .dismiss(DismissAction { actionRan = true }))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(actionRan)
    }

    /// `navigate(to:)` with `.home` pushes the home screen.
    @MainActor
    func test_navigate_home() throws {
        subject.navigate(to: .home)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AgentAccessHomeView>)
    }

    /// `navigate(to:)` with `.pairing` pushes the pairing screen.
    @MainActor
    func test_navigate_pairing() throws {
        subject.navigate(to: .pairing)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AgentAccessPairingView>)
    }

    /// `navigate(to:)` with `.share` presents the system share sheet with the text.
    @MainActor
    func test_navigate_share() throws {
        subject.navigate(to: .share(text: "token"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `start()` has no effect.
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}
