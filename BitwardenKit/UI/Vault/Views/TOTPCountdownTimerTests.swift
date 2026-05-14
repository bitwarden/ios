import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import Testing

struct TOTPCountdownTimerTests {
    // MARK: Tests

    /// `onExpiration` is called when the timer fires for a code whose generation date is in the past.
    @Test
    @MainActor
    func onExpiration_oldDate() {
        let expiredCode = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: .distantPast,
            period: 3,
        )
        var didExpire = false
        let subject = TOTPCountdownTimer(
            timeProvider: CurrentTime(),
            timerInterval: 0.1,
            totpCode: expiredCode,
            onExpiration: { didExpire = true },
        )
        waitFor(didExpire)
        _ = subject
    }

    /// `TOTPCountdownTimer` is deallocated when the last external strong reference is
    /// released, confirming the timer block does not create a retain cycle.
    @Test
    @MainActor
    func timer_doesNotCreateRetainCycle() {
        weak var weakSubject: TOTPCountdownTimer?
        do {
            let subject = makeSubject(period: 30, mockTime: Date(timeIntervalSinceReferenceDate: 20))
            weakSubject = subject
        }
        #expect(weakSubject == nil)
    }

    /// `timerColor()` returns the normal (tintPrimary) color when more than
    /// `Constants.totpUrgentCountdownThreshold` seconds remain.
    @Test
    func timerColor_normal() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold + 3
        let mockTime = Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining))
        let subject = makeSubject(period: period, mockTime: mockTime)

        #expect(subject.timerColor() == SharedAsset.Colors.tintPrimary.swiftUIColor)
    }

    /// `timerColor()` returns the normal (tintPrimary) color when exactly one second above
    /// `Constants.totpUrgentCountdownThreshold` remains (boundary).
    @Test
    func timerColor_oneAboveThreshold() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold + 1
        let mockTime = Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining))
        let subject = makeSubject(period: period, mockTime: mockTime)

        #expect(subject.timerColor() == SharedAsset.Colors.tintPrimary.swiftUIColor)
    }

    /// `timerColor()` returns the urgent (error) color at exactly
    /// `Constants.totpUrgentCountdownThreshold` seconds remaining (boundary).
    @Test
    func timerColor_atThreshold() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold
        let mockTime = Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining))
        let subject = makeSubject(period: period, mockTime: mockTime)

        #expect(subject.timerColor() == SharedAsset.Colors.danger.swiftUIColor)
    }

    /// `timerColor()` returns the urgent (error) color when well below
    /// `Constants.totpUrgentCountdownThreshold` seconds remain.
    @Test
    func timerColor_urgent() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold - 2
        let mockTime = Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining))
        let subject = makeSubject(period: period, mockTime: mockTime)

        #expect(subject.timerColor() == SharedAsset.Colors.danger.swiftUIColor)
    }

    // MARK: Private Methods

    /// Creates a `TOTPCountdownTimer` with a frozen clock set to the given `mockTime`
    /// and a code generated at the reference date start.
    ///
    /// - Parameters:
    ///   - period: The TOTP period in seconds.
    ///   - mockTime: The time the clock is frozen at for the test.
    ///
    /// - Returns: A configured `TOTPCountdownTimer` with a long timer interval so it
    ///   won't fire during the test.
    ///
    private func makeSubject(period: Int, mockTime: Date) -> TOTPCountdownTimer {
        TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(mockTime)),
            timerInterval: 60,
            totpCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: .distantPast,
                period: UInt32(period),
            ),
            onExpiration: nil,
        )
    }
}
