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
            divergenceThreshold: 5.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertFalse(result.isReboot)
        XCTAssertEqual(result.elapsedMonotonic, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.divergence, 0, accuracy: 0.1)
        // effectiveElapsed uses monotonic exclusively
        XCTAssertEqual(result.effectiveElapsed, result.elapsedMonotonic, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// detection when monotonic and wall-clock times diverge significantly.
    func test_calculateTamperResistantElapsedTime_largeDivergence() {
        let lastMonotonicTime = subject.monotonicTime + 10000
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-300)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertTrue(result.tamperingDetected)
        XCTAssert(result.divergence > 5.0)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that small divergence within threshold is not flagged as tampering.
    func test_calculateTamperResistantElapsedTime_smallDivergenceWithinThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-153)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertFalse(result.isReboot)
        XCTAssertEqual(result.divergence, 3, accuracy: 0.1)
        // effectiveElapsed is monotonic, not the larger wall-clock value
        XCTAssertEqual(result.effectiveElapsed, 150, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// divergence exactly at threshold boundary.
    func test_calculateTamperResistantElapsedTime_divergenceAtThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-155)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.divergence, 5, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that divergence just over threshold triggers detection.
    func test_calculateTamperResistantElapsedTime_divergenceOverThreshold() {
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-156)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertTrue(result.tamperingDetected)
        XCTAssertEqual(result.divergence, 6, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that effectiveElapsed uses monotonic time exclusively, not max of both clocks.
    func test_calculateTamperResistantElapsedTime_effectiveElapsedIsMonotonic() {
        let lastMonotonicTime = subject.monotonicTime - 140
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-143)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.elapsedMonotonic, 140, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, 143, accuracy: 0.1)
        // effectiveElapsed is monotonic, not wall-clock
        XCTAssertEqual(result.effectiveElapsed, result.elapsedMonotonic, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// zero elapsed time scenario.
    func test_calculateTamperResistantElapsedTime_zeroElapsed() {
        let lastMonotonicTime = subject.monotonicTime
        let lastWallClockTime = subject.presentTime

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertFalse(result.isReboot)
        XCTAssertEqual(result.elapsedMonotonic, 0, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, 0, accuracy: 0.1)
        XCTAssertEqual(result.divergence, 0, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, 0, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:divergenceThreshold:)` tests
    /// that a negative monotonic elapsed time sets `isReboot` and forces `tamperingDetected`.
    func test_calculateTamperResistantElapsedTime_negativeMonotonicElapsed_rebootDetected() {
        let lastMonotonicTime = subject.monotonicTime + 5000
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-300)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )

        XCTAssertTrue(result.isReboot)
        XCTAssertTrue(result.tamperingDetected)
        XCTAssert(result.elapsedMonotonic < 0)
        // effectiveElapsed is monotonic (negative on reboot); callers check tamperingDetected first
        XCTAssertEqual(result.effectiveElapsed, result.elapsedMonotonic, accuracy: 0.1)
    }

    /// `calculateTamperResistantElapsedTime(lastMonotonicTime:lastWallClockTime:)` tests that the default
    /// threshold is 5.0 seconds — tight enough to catch obvious attacks while above normal NTP drift.
    func test_calculateTamperResistantElapsedTime_defaultThreshold() {
        // Divergence of 4s: within new 5s default threshold → no tampering
        let lastMonotonicTime = subject.monotonicTime - 150
        let lastWallClockTime = subject.presentTime.addingTimeInterval(-154)

        let result = subject.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertEqual(result.divergence, 4, accuracy: 0.1)
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
            divergenceThreshold: 5.0,
        )

        XCTAssertFalse(result.tamperingDetected)
        XCTAssertFalse(result.isReboot)
        XCTAssertEqual(result.elapsedMonotonic, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.elapsedWallClock, elapsedTime, accuracy: 0.1)
        XCTAssertEqual(result.effectiveElapsed, result.elapsedMonotonic, accuracy: 0.1)
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
