import BitwardenResources
import XCTest

@testable import BitwardenKit

class AlertFlightRecorderTests: BitwardenTestCase {
    // MARK: Tests

    /// `confirmDeleteLog(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting a log.
    func test_confirmDeleteLog() async throws {
        var actionCalled = false
        let subject = Alert.confirmDeleteLog(isBulkDeletion: false) { actionCalled = true }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDeleteThisLog)
        XCTAssertNil(subject.message)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.yes)
        XCTAssertTrue(actionCalled)
    }

    /// `confirmDeleteLog(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting all logs.
    func test_confirmDeleteLog_bulkDeletion() async throws {
        var actionCalled = false
        let subject = Alert.confirmDeleteLog(isBulkDeletion: true) { actionCalled = true }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDeleteAllRecordedLogs)
        XCTAssertNil(subject.message)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.yes)
        XCTAssertTrue(actionCalled)
    }
}
