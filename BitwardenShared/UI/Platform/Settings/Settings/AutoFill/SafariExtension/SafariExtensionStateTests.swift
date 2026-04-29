import XCTest

@testable import BitwardenShared

// MARK: - SafariExtensionStateTests

class SafariExtensionStateTests: BitwardenTestCase {
    /// `extensionActivated` moves the setup status to `.setupOpened` when starting from `.notStarted`.
    func test_extensionActivated_true_fromNotStarted() {
        var subject = SafariExtensionState()

        subject.extensionActivated = true

        XCTAssertEqual(subject.setupStatus, .setupOpened)
        XCTAssertTrue(subject.extensionActivated)
        XCTAssertFalse(subject.extensionEnabled)
    }

    /// `extensionActivated` keeps `.enabled` unchanged when already enabled.
    func test_extensionActivated_true_fromEnabled() {
        var subject = SafariExtensionState(setupStatus: .enabled)

        subject.extensionActivated = true

        XCTAssertEqual(subject.setupStatus, .enabled)
        XCTAssertTrue(subject.extensionActivated)
        XCTAssertTrue(subject.extensionEnabled)
    }

    /// `extensionActivated` resets the setup status to `.notStarted` when set to `false`.
    func test_extensionActivated_false() {
        var subject = SafariExtensionState(setupStatus: .setupOpened)

        subject.extensionActivated = false

        XCTAssertEqual(subject.setupStatus, .notStarted)
        XCTAssertFalse(subject.extensionActivated)
        XCTAssertFalse(subject.extensionEnabled)
    }

    /// `extensionEnabled` moves the setup status to `.enabled` when set to `true`.
    func test_extensionEnabled_true() {
        var subject = SafariExtensionState(setupStatus: .setupOpened)

        subject.extensionEnabled = true

        XCTAssertEqual(subject.setupStatus, .enabled)
        XCTAssertTrue(subject.extensionActivated)
        XCTAssertTrue(subject.extensionEnabled)
    }

    /// `extensionEnabled` returns to `.setupOpened` when disabling after setup was opened.
    func test_extensionEnabled_false_afterSetupOpened() {
        var subject = SafariExtensionState(setupStatus: .enabled)

        subject.extensionEnabled = false

        XCTAssertEqual(subject.setupStatus, .setupOpened)
        XCTAssertTrue(subject.extensionActivated)
        XCTAssertFalse(subject.extensionEnabled)
    }

    /// `extensionEnabled` returns to `.notStarted` when disabling from an untouched state.
    func test_extensionEnabled_false_fromNotStarted() {
        var subject = SafariExtensionState()

        subject.extensionEnabled = false

        XCTAssertEqual(subject.setupStatus, .notStarted)
        XCTAssertFalse(subject.extensionActivated)
        XCTAssertFalse(subject.extensionEnabled)
    }
}
