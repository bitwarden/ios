import BitwardenKit
import XCTest

@testable import BitwardenShared

class AccountSecurityStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: AccountSecurityState!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = AccountSecurityState()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests - availableTimeoutOptions

    /// Tests that `.never` policy type returns all timeout options.
    func test_availableTimeoutOptions_neverPolicy_returnsAllCases() {
        subject.policyTimeoutType = .never
        subject.policyTimeoutValue = 0

        let options = subject.availableTimeoutOptions

        XCTAssertEqual(options.count, SessionTimeoutValue.allCases.count)
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))
        XCTAssertTrue(options.contains(.thirtyMinutes))
        XCTAssertTrue(options.contains(.oneHour))
        XCTAssertTrue(options.contains(.fourHours))
        XCTAssertTrue(options.contains(.onAppRestart))
        XCTAssertTrue(options.contains(.never))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })
    }

    /// Tests that `.onAppRestart` policy type filters out `.never`.
    func test_availableTimeoutOptions_onAppRestartPolicy_filtersOutNever() {
        subject.policyTimeoutType = .onAppRestart
        subject.policyTimeoutValue = 0

        let options = subject.availableTimeoutOptions

        XCTAssertFalse(options.contains(.never))
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))
        XCTAssertTrue(options.contains(.thirtyMinutes))
        XCTAssertTrue(options.contains(.oneHour))
        XCTAssertTrue(options.contains(.fourHours))
        XCTAssertTrue(options.contains(.onAppRestart))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })
    }

    /// Tests that `.immediately` policy type returns only `.immediately`.
    func test_availableTimeoutOptions_immediatelyPolicy_returnsOnlyImmediately() {
        subject.policyTimeoutType = .immediately
        subject.policyTimeoutValue = 0

        let options = subject.availableTimeoutOptions

        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options.first, .immediately)
    }

    /// Tests that `.custom` policy type filters by maximum value.
    func test_availableTimeoutOptions_customPolicy_filtersUpToMaxValue() {
        subject.policyTimeoutType = .custom
        subject.policyTimeoutValue = 60

        let options = subject.availableTimeoutOptions

        // Should include options <= 60 minutes
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))
        XCTAssertTrue(options.contains(.thirtyMinutes))
        XCTAssertTrue(options.contains(.oneHour))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })

        // Should not include options > 60 minutes
        XCTAssertFalse(options.contains(.fourHours))

        // Should not include non-minute values
        XCTAssertFalse(options.contains(.never))
        XCTAssertFalse(options.contains(.onAppRestart))
    }

    /// Tests that `.custom` policy type with low value filters correctly.
    func test_availableTimeoutOptions_customPolicy_lowValue() {
        subject.policyTimeoutType = .custom
        subject.policyTimeoutValue = 5

        let options = subject.availableTimeoutOptions

        // Should include options <= 5 minutes
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })

        // Should not include options > 5 minutes
        XCTAssertFalse(options.contains(.fifteenMinutes))
        XCTAssertFalse(options.contains(.thirtyMinutes))
        XCTAssertFalse(options.contains(.oneHour))
        XCTAssertFalse(options.contains(.fourHours))
    }

    /// Tests that `.custom` policy type with high value includes all minute-based options.
    func test_availableTimeoutOptions_customPolicy_highValue() {
        subject.policyTimeoutType = .custom
        subject.policyTimeoutValue = 1000

        let options = subject.availableTimeoutOptions

        // Should include all minute-based options
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))
        XCTAssertTrue(options.contains(.thirtyMinutes))
        XCTAssertTrue(options.contains(.oneHour))
        XCTAssertTrue(options.contains(.fourHours))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })

        // Should not include non-minute values
        XCTAssertFalse(options.contains(.never))
        XCTAssertFalse(options.contains(.onAppRestart))
    }

    /// Tests that `nil` policy type with value > 0 filters by maximum value.
    func test_availableTimeoutOptions_nilPolicy_withPositiveValue() {
        subject.policyTimeoutType = nil
        subject.policyTimeoutValue = 30

        let options = subject.availableTimeoutOptions

        // Should include options <= 30 minutes
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))
        XCTAssertTrue(options.contains(.thirtyMinutes))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })

        // Should not include options > 30 minutes
        XCTAssertFalse(options.contains(.oneHour))
        XCTAssertFalse(options.contains(.fourHours))

        // Should not include non-minute values
        XCTAssertFalse(options.contains(.never))
        XCTAssertFalse(options.contains(.onAppRestart))
    }

    /// Tests that `nil` policy type with value == 0 returns all options.
    func test_availableTimeoutOptions_nilPolicy_withZeroValue() {
        subject.policyTimeoutType = nil
        subject.policyTimeoutValue = 0

        let options = subject.availableTimeoutOptions

        XCTAssertEqual(options.count, SessionTimeoutValue.allCases.count)
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))
        XCTAssertTrue(options.contains(.thirtyMinutes))
        XCTAssertTrue(options.contains(.oneHour))
        XCTAssertTrue(options.contains(.fourHours))
        XCTAssertTrue(options.contains(.onAppRestart))
        XCTAssertTrue(options.contains(.never))
        XCTAssertTrue(options.contains { $0.isCustomPlaceholder })
    }

    /// Tests that `nil` policy type with negative value returns all options.
    func test_availableTimeoutOptions_nilPolicy_withNegativeValue() {
        subject.policyTimeoutType = nil
        subject.policyTimeoutValue = -1

        let options = subject.availableTimeoutOptions

        // Negative value should be treated as 0 (no restriction)
        XCTAssertEqual(options.count, SessionTimeoutValue.allCases.count)
    }

    /// Tests boundary condition: exactly matching the policy value.
    func test_availableTimeoutOptions_customPolicy_exactMatch() {
        subject.policyTimeoutType = .custom
        subject.policyTimeoutValue = 15

        let options = subject.availableTimeoutOptions

        // Should include the exact value
        XCTAssertTrue(options.contains(.fifteenMinutes))

        // Should include smaller values
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))

        // Should not include larger values
        XCTAssertFalse(options.contains(.thirtyMinutes))
        XCTAssertFalse(options.contains(.oneHour))
        XCTAssertFalse(options.contains(.fourHours))
    }

    /// Tests boundary condition: value between two predefined options.
    func test_availableTimeoutOptions_customPolicy_betweenOptions() {
        subject.policyTimeoutType = .custom
        subject.policyTimeoutValue = 20

        let options = subject.availableTimeoutOptions

        // Should include values <= 20
        XCTAssertTrue(options.contains(.immediately))
        XCTAssertTrue(options.contains(.oneMinute))
        XCTAssertTrue(options.contains(.fiveMinutes))
        XCTAssertTrue(options.contains(.fifteenMinutes))

        // Should not include 30 (> 20)
        XCTAssertFalse(options.contains(.thirtyMinutes))
    }
}
