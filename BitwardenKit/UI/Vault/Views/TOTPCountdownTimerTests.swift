import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenKit

final class TOTPCountdownTimerTests: BitwardenTestCase {
    // MARK: Properties

    var subject: TOTPCountdownTimer!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = TOTPCountdownTimer(
            timeProvider: CurrentTime(),
            timerInterval: 0.5,
            totpCode: .init(
                code: "123456",
                codeGenerationDate: .distantPast,
                period: 30,
            ),
            onExpiration: {},
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    func test_onExpiration_oldDate() {
        var didExpire = false
        subject = TOTPCountdownTimer(
            timeProvider: CurrentTime(),
            timerInterval: 0.1,
            totpCode: .init(
                code: "123456",
                codeGenerationDate: .distantPast,
                period: 3,
            ),
            onExpiration: {
                didExpire = true
            },
        )
        waitFor(didExpire)
        XCTAssertTrue(didExpire)
    }

    /// `timerColor()` returns the normal (tintPrimary) color when more than
    /// `Constants.totpUrgentCountdownThreshold` seconds remain.
    func test_timerColor_normal() {
        // 10 seconds remain: timeIntervalSinceReferenceDate=20, period=30 → 30-20=10 > 7
        subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: 20))),
            timerInterval: 60,
            totpCode: .init(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: 30,
            ),
            onExpiration: nil,
        )
        XCTAssertEqual(subject.timerColor(), SharedAsset.Colors.tintPrimary.swiftUIColor)
    }

    /// `timerColor()` returns the urgent (error) color when
    /// `Constants.totpUrgentCountdownThreshold` or fewer seconds remain.
    func test_timerColor_urgent() {
        // 5 seconds remain: timeIntervalSinceReferenceDate=25, period=30 → 30-25=5 <= 7
        subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: 25))),
            timerInterval: 60,
            totpCode: .init(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: 30,
            ),
            onExpiration: nil,
        )
        XCTAssertEqual(subject.timerColor(), SharedAsset.Colors.error.swiftUIColor)
    }
}
