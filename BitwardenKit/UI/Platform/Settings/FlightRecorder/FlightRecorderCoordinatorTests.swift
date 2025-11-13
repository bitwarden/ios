import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenKit

class FlightRecorderCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: FlightRecorderCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = FlightRecorderCoordinator(
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

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.enableFlightRecorder` presents the enable flight recorder view.
    @MainActor
    func test_navigateTo_enableFlightRecorder() throws {
        subject.navigate(to: .enableFlightRecorder)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is EnableFlightRecorderView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.flightRecorderLogs` presents the flight recorder logs view.
    @MainActor
    func test_navigateTo_flightRecorderLogs() throws {
        subject.navigate(to: .flightRecorderLogs)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is FlightRecorderLogsView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.shareURL(_:)` presents an activity view controller to share the URL.
    @MainActor
    func test_navigateTo_shareURL() throws {
        subject.navigate(to: .shareURL(.example))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `navigate(to:)` with `.shareURL(_:)` presents an activity view controller to share the URLs.
    @MainActor
    func test_navigateTo_shareURLs() throws {
        subject.navigate(to: .shareURLs([.example]))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }
}
