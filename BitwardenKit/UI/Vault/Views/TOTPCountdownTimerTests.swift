import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import Testing

struct TOTPCountdownTimerTests {
    // MARK: Tests

    /// `onExpiration` is called when the timer fires for a code whose generation date is in the past.
    @Test @MainActor
    func onExpiration_oldDate() async throws {
        try await confirmation("onExpiration was called") { confirm in
            let subject = TOTPCountdownTimer(
                timeProvider: CurrentTime(),
                timerInterval: 0.1,
                totpCode: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: .distantPast,
                    period: 3,
                ),
                onExpiration: { confirm() },
            )
            try await Task.sleep(nanoseconds: 1_000_000_000)
            _ = subject
        }
    }

    /// `timerColor()` returns the normal (tintPrimary) color when more than
    /// `Constants.totpUrgentCountdownThreshold` seconds remain.
    @Test
    func timerColor_normal() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold + 3
        let subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining)))),
            timerInterval: 60,
            totpCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: UInt32(period),
            ),
            onExpiration: nil,
        )
        #expect(subject.timerColor() == SharedAsset.Colors.tintPrimary.swiftUIColor)
    }

    /// `timerColor()` returns the normal (tintPrimary) color when exactly one second above
    /// `Constants.totpUrgentCountdownThreshold` remains (boundary).
    @Test
    func timerColor_oneAboveThreshold() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold + 1
        let subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining)))),
            timerInterval: 60,
            totpCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: UInt32(period),
            ),
            onExpiration: nil,
        )
        #expect(subject.timerColor() == SharedAsset.Colors.tintPrimary.swiftUIColor)
    }

    /// `timerColor()` returns the urgent (error) color at exactly
    /// `Constants.totpUrgentCountdownThreshold` seconds remaining (boundary).
    @Test
    func timerColor_atThreshold() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold
        let subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining)))),
            timerInterval: 60,
            totpCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: UInt32(period),
            ),
            onExpiration: nil,
        )
        #expect(subject.timerColor() == SharedAsset.Colors.error.swiftUIColor)
    }

    /// `timerColor()` returns the urgent (error) color when well below
    /// `Constants.totpUrgentCountdownThreshold` seconds remain.
    @Test
    func timerColor_urgent() {
        let period = 30
        let secondsRemaining = Constants.totpUrgentCountdownThreshold - 2
        let subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: Double(period - secondsRemaining)))),
            timerInterval: 60,
            totpCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: UInt32(period),
            ),
            onExpiration: nil,
        )
        #expect(subject.timerColor() == SharedAsset.Colors.error.swiftUIColor)
    }
}
