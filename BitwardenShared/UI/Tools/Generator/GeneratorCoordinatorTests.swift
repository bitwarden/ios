import SwiftUI
import XCTest

@testable import BitwardenShared

class GeneratorCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockGeneratorCoordinatorDelegate!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: GeneratorCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockGeneratorCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()

        subject = GeneratorCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
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

    /// `navigate(to:)` with `.cancel` instructs the delegate that the generator flow has been
    /// cancelled.
    @MainActor
    func test_navigateTo_cancel() {
        subject.navigate(to: .cancel)
        XCTAssertTrue(delegate.didCancelGeneratorCalled)
    }

    /// `navigate(to:)` with `.complete` instructs the delegate that the generator flow has
    /// completed.
    @MainActor
    func test_navigateTo_complete() {
        subject.navigate(to: .complete(type: .username, value: "email@example.com"))
        XCTAssertTrue(delegate.didCompleteGeneratorCalled)
        XCTAssertEqual(delegate.didCompleteGeneratorType, .username)
        XCTAssertEqual(delegate.didCompleteGeneratorValue, "email@example.com")
    }

    /// `navigate(to:)` with `.generator` and a delegate pushes the generator view onto the stack
    /// navigator.
    @MainActor
    func test_navigateTo_generator_withDelegate() throws {
        subject.navigate(to: .generator())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.presentationMode, .tab)
        XCTAssertEqual(store.state.generatorType, .password)
    }

    /// `navigate(to:)` with `.generator` and an email website pushes the generator view onto the
    /// stack navigator.
    @MainActor
    func test_navigateTo_generator_withEmailType() throws {
        subject.navigate(to: .generator(emailWebsite: "bitwarden.com"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.usernameState.emailWebsite, "bitwarden.com")
    }

    /// `navigate(to:)` with `.generator` and `.password` pushes the generator view onto the stack
    /// navigator without the type field visible.
    @MainActor
    func test_navigateTo_generator_withPassword() throws {
        subject.navigate(to: .generator(staticType: .password))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.generatorType, .password)
        XCTAssertEqual(store.state.presentationMode, .inPlace)
    }

    /// `navigate(to:)` with `.generator` and `.username` pushes the generator view onto the stack
    /// navigator without the type field visible.
    @MainActor
    func test_navigateTo_generator_withUsername() throws {
        subject.navigate(to: .generator(staticType: .username))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.generatorType, .username)
        XCTAssertEqual(store.state.presentationMode, .inPlace)
    }

    /// `navigate(to:)` with `.generator` and without a delegate pushes the generator view onto the
    /// stack navigator without the select button or dismiss button visible.
    @MainActor
    func test_navigateTo_generator_withoutDelegate() throws {
        subject = GeneratorCoordinator(
            delegate: nil,
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
        subject.navigate(to: .generator())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)

        let store = try XCTUnwrap((action.view as? GeneratorView)?.store)
        XCTAssertEqual(store.state.presentationMode, .tab)
        XCTAssertEqual(store.state.generatorType, .password)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .generatorHistory)
        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.generator` pushes the generator view onto the stack navigator.
    @MainActor
    func test_navigateTo_generator() throws {
        subject.navigate(to: .generator())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is GeneratorView)
    }

    /// `navigate(to:)` with `.generatorHistory` presents the generator history view.
    @MainActor
    func test_navigateTo_generatorHistory() throws {
        subject.navigate(to: .generatorHistory)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.passwordHistoryCoordinator.isStarted)
        XCTAssertEqual(module.passwordHistoryCoordinator.routes.last, .passwordHistoryList(.generator))
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
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
    @MainActor
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
