import SwiftUI
import XCTest

@testable import BitwardenShared

class GeneratorCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockGeneratorCoordinatorDelegate!
    var stackNavigator: MockStackNavigator!
    var subject: GeneratorCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockGeneratorCoordinatorDelegate()
        stackNavigator = MockStackNavigator()

        subject = GeneratorCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.cancel` instructs the delegate that the generator flow has been
    /// cancelled.
    func test_navigateTo_cancel() {
        subject.navigate(to: .cancel)
        XCTAssertTrue(delegate.didCancelGeneratorCalled)
    }

    /// `navigate(to:)` with `.complete` instructs the delegate that the generator flow has
    /// completed.
    func test_navigateTo_complete() {
        subject.navigate(to: .complete(type: .username, value: "email@example.com"))
        XCTAssertTrue(delegate.didCompleteGeneratorCalled)
        XCTAssertEqual(delegate.didCompleteGeneratorType, .username)
        XCTAssertEqual(delegate.didCompleteGeneratorValue, "email@example.com")
    }

    /// `navigate(to:)` with `.generator` and a delegate pushes the generator view onto the stack
    /// navigator.
    func test_navigateTo_generator_withDelegate() throws {
        subject.navigate(to: .generator())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertTrue(store.state.isSelectButtonVisible)
        XCTAssertTrue(store.state.isDismissButtonVisible)
        XCTAssertEqual(store.state.generatorType, .password)
        XCTAssertTrue(store.state.isTypeFieldVisible)
    }

    /// `navigate(to:)` with `.generator` and `.password` pushes the generator view onto the stack
    /// navigator without the type field visible.
    func test_navigateTo_generator_withPassword() throws {
        subject.navigate(to: .generator(staticType: .password))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.generatorType, .password)
        XCTAssertFalse(store.state.isTypeFieldVisible)
    }

    /// `navigate(to:)` with `.generator` and `.username` pushes the generator view onto the stack
    /// navigator without the type field visible.
    func test_navigateTo_generator_withUsername() throws {
        subject.navigate(to: .generator(staticType: .username))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.generatorType, .username)
        XCTAssertFalse(store.state.isTypeFieldVisible)
    }

    /// `navigate(to:)` with `.generator` and without a delegate pushes the generator view onto the
    /// stack navigator without the select button or dismiss button visible.
    func test_navigateTo_generator_withoutDelegate() throws {
        subject = GeneratorCoordinator(
            delegate: nil,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
        subject.navigate(to: .generator())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertFalse(store.state.isSelectButtonVisible)
        XCTAssertFalse(store.state.isDismissButtonVisible)
        XCTAssertEqual(store.state.generatorType, .password)
        XCTAssertTrue(store.state.isTypeFieldVisible)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .generatorHistory)
        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.generator` pushes the generator view onto the stack navigator.
    func test_navigateTo_generator() throws {
        subject.navigate(to: .generator())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)
    }

    /// `navigate(to:)` with `.generatorHistory` presents the generator history view.
    func test_navigateTo_generatorHistory() throws {
        subject.navigate(to: .generatorHistory)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is UIHostingController<GeneratorHistoryView>)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    func test_show_hide_loadingOverlay() throws {
        stackNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(stackNavigator.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` navigates to the generator view.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is GeneratorView)
    }
}

// MARK: - MockGeneratorCoordinatorDelegate

class MockGeneratorCoordinatorDelegate: GeneratorCoordinatorDelegate {
    var didCancelGeneratorCalled = false

    var didCompleteGeneratorCalled = false
    var didCompleteGeneratorType: GeneratorType?
    var didCompleteGeneratorValue: String?

    func didCancelGenerator() {
        didCancelGeneratorCalled = true
    }

    func didCompleteGenerator(for type: GeneratorType, with value: String) {
        didCompleteGeneratorCalled = true
        didCompleteGeneratorType = type
        didCompleteGeneratorValue = value
    }
}
