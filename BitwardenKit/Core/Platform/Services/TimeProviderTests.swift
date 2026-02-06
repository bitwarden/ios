import XCTest

@testable import BitwardenKit

// MARK: - TimeProviderTests

class TimeProviderTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CurrentTime!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = CurrentTime()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// normal operation where both clocks show the same elapsed time.
    func test_calculateTamperResistantElapsedTime_normalOperation() {
        let elapsedTime: TimeInterval = 150
        let lastMonotonicTime = subject.monotonicTime - elapsedTime
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-elapsedTime)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.elapsedMonotonic, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.divergence, 0, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, elapsedTime, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// detection when monotonic and wall-clock times diverge significantly.
    func test_calculateTamperResistantElapsedTime_largeDivergence() {
        let lastMonotonicTime = subject.monotonicTime + 10000
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-300)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertTrue(result.tamperingDetected)
        XCTAssert(result.divergence > 15.0)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that small divergence within threshold is not flagged as tampering.
    func test_calculateTamperResistantElapsedTime_smallDivergenceWithinThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-155)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.divergence, 5, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, 155, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// divergence exactly at threshold boundary.
    func test_calculateTamperResistantElapsedTime_divergenceAtThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-165)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.divergence, 15, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that divergence just over threshold triggers detection.
    func test_calculateTamperResistantElapsedTime_divergenceOverThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-166)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertTrue(result.tamperingDetected)
        XCTAssertEqual(result.divergence, 16, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that max() selects the larger elapsed time for safety.
    func test_calculateTamperResistantElapsedTime_maxProtection() {
        let lastMonotonicTime = subject.monotonicTime - 140
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-150)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.elapsedMonotonic, 140, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, 150, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, 150, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// zero elapsed time scenario.
    func test_calculateTamperResistantElapsedTime_zeroElapsed() {
        let lastMonotonicTime = subject.monotonicTime
        let lastWallClockTime = subject.presentTime

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.elapsedMonotonic, 0, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, 0, accuracy: 0.1)
        XCTAssertEqual(result.divergence, 0, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, 0, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// negative monotonic elapsed time (reboot scenario).
    func test_calculateTamperResistantElapsedTime_negativeMonotonicElapsed() {
        let lastMonotonicTime = subject.monotonicTime + 5000
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-300)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertTrue(result.tamperingDetected)
        XCTAssert(result.elapsedMonotonic < 0)
        XCTAssertEqual(result.elapsedWallClock, 300, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, 300, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:)` tests default threshold
    /// parameter.
    func test_calculateTamperResistantElapsedTime_defaultThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-165)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
        )

        XCTAssertFalse(result.tamperingDetected)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// large elapsed time values.
    func test_calculateTamperResistantElapsedTime_largeElapsedTime() {
        let elapsedTime: TimeInterval = 24000
        let lastMonotonicTime = subject.monotonicTime - elapsedTime
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-elapsedTime)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.elapsedMonotonic, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, elapsedTime, accuracy: 0.1)
    }

    // MARK: timeSince Tests

    /// `timeSince(_:)` returns elapsed time for a past date.
    func test_timeSince_pastDate() {
        let pastDate = subject.presentTime.addingTimeInterval(-150)

        let elapsed = subject.timeSince(pastDate)

        XCTAssertEqual(elapsed, 150, accuracy: 0.1)
        XCTAssert(elapsed > 0)
    }

    /// `timeSince(_:)` returns zero for current date.
    func test_timeSince_currentDate() {
        let currentDate = subject.presentTime

        let elapsed = subject.timeSince(currentDate)

        XCTAssertEqual(elapsed, 0, accuracy: 0.1)
    }

    /// `timeSince(_:)` returns negative elapsed time for a future date.
    func test_timeSince_futureDate() {
        let futureDate = subject.presentTime.addingTimeInterval(100)

        let elapsed = subject.timeSince(futureDate)

        XCTAssertEqual(elapsed, -100, accuracy: 0.1)
        XCTAssert(elapsed < 0)
    }

    /// `timeSince(_:)` handles large time intervals for dates far in the past.
    func test_timeSince_farPastDate() {
        let farPastDate = subject.presentTime.addingTimeInterval(-86400)

        let elapsed = subject.timeSince(farPastDate)

        XCTAssertEqual(elapsed, 86400, accuracy: 0.1)
    }
}
