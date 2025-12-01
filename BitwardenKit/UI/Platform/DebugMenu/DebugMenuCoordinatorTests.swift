import BitwardenKit
//import BitwardenKitMocks
import SwiftUI
import XCTest
//
//@testable import BitwardenShared
//
//class DebugMenuCoordinatorTests: BitwardenTestCase {
//    // MARK: Properties
//
//    var appSettingsStore: MockAppSettingsStore!
//    var configService: MockConfigService!
//    var delegate: MockDebugMenuCoordinatorDelegate!
//    var stackNavigator: MockStackNavigator!
//    var subject: DebugMenuCoordinator!
//
//    // MARK: Setup & Teardown
//
//    override func setUp() {
//        super.setUp()
//
//        appSettingsStore = MockAppSettingsStore()
//        configService = MockConfigService()
//        delegate = MockDebugMenuCoordinatorDelegate()
//        stackNavigator = MockStackNavigator()
//
//        subject = DebugMenuCoordinator(
//            delegate: delegate,
//            services: ServiceContainer.withMocks(
//                appSettingsStore: appSettingsStore,
//                configService: configService,
//            ),
//            stackNavigator: stackNavigator,
//        )
//    }
//
//    override func tearDown() {
//        super.tearDown()
//
//        appSettingsStore = nil
//        configService = nil
//        delegate = nil
//        stackNavigator = nil
//        subject = nil
//    }
//
//    // MARK: Tests
//
//    /// `navigate(to:)` with `.dismiss` dismisses the view.
//    @MainActor
//    func test_navigate_dismiss() throws {
//        subject.navigate(to: .dismiss)
//
//        let action = try XCTUnwrap(stackNavigator.actions.last)
//        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
//        XCTAssertTrue(delegate.didDismissDebugMenuCalled)
//    }
//
//    /// `start()` correctly shows the `DebugMenuView`.
//    @MainActor
//    func test_start() {
//        subject.start()
//
//        XCTAssertTrue(stackNavigator.actions.last?.view is DebugMenuView)
//    }
//}
//
class MockDebugMenuCoordinatorDelegate: DebugMenuCoordinatorDelegate {
    var didDismissDebugMenuCalled = false

    func didDismissDebugMenu() {
        didDismissDebugMenuCalled = true
    }
}
