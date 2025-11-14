// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ExpiredLinkViewTests

class ExpiredLinkViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExpiredLinkState, ExpiredLinkAction, Void>!
    var subject: ExpiredLinkView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ExpiredLinkState())
        subject = ExpiredLinkView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissTapped)
    }

    /// Tapping the restart registration button dispatches the `.restartRegistrationTapped` action.
    @MainActor
    func test_restartRegistration() throws {
        let button = try subject.inspect().find(button: Localizations.restartRegistration)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .restartRegistrationTapped)
    }

    /// Tapping the log in button dispatches the `.logInTapped` action.
    @MainActor
    func test_logIn() throws {
        let button = try subject.inspect().find(button: Localizations.logIn)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .logInTapped)
    }
}
