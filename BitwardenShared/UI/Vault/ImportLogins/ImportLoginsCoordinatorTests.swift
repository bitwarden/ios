import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenShared

class ImportLoginsCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockImportLoginsCoordinatorDelegate!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: ImportLoginsCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockImportLoginsCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()

        subject = ImportLoginsCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        module = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `handleEvent(_:context:)` with `.completeImportLogins` notifies the delegate that the user
    /// completed importing logins.
    @MainActor
    func test_handleEvent_completeImportLogins() async {
        await subject.handleEvent(.completeImportLogins)
        XCTAssertTrue(delegate.didCompleteLoginsImportCalled)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.importLogins` pushes the import logins view onto the stack navigator.
    @MainActor
    func test_navigateTo_importLogins() throws {
        subject.navigate(to: .importLogins(.vault))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is ImportLoginsView)
    }

    /// `navigate(to:)` with `.importLoginsSuccess` presents the import logins success view onto the stack navigator.
    @MainActor
    func test_navigateTo_importLoginsSuccess() throws {
        subject.navigate(to: .importLoginsSuccess)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is ImportLoginsSuccessView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `start()` has no effect.
    @MainActor
    func test_start() {
        subject.start()
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

class MockImportLoginsCoordinatorDelegate: ImportLoginsCoordinatorDelegate {
    var didCompleteLoginsImportCalled = false

    func didCompleteLoginsImport() {
        didCompleteLoginsImportCalled = true
    }
}
