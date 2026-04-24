import BitwardenKitMocks
import BitwardenResources
import Foundation
import Testing

@testable import BitwardenKit

struct TOTPCountdownTimerTests {
    // MARK: Tests

    @Test @MainActor
    func onExpiration_oldDate() async {
        await confirmation("onExpiration was called") { confirm in
            let subject = TOTPCountdownTimer(
                timeProvider: CurrentTime(),
                timerInterval: 0.1,
                totpCode: .init(
                    code: "123456",
                    codeGenerationDate: .distantPast,
                    period: 3,
                ),
                onExpiration: { confirm() },
            )
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            _ = subject
        }
    }

    /// `timerColor()` returns the normal (tintPrimary) color when more than
    /// `Constants.totpUrgentCountdownThreshold` seconds remain.
    @Test
    func timerColor_normal() {
        // 10 seconds remain: timeIntervalSinceReferenceDate=20, period=30 → 30-20=10 > 7
        let subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: 20))),
            timerInterval: 60,
            totpCode: .init(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: 30,
            ),
            onExpiration: nil,
        )
        #expect(subject.timerColor() == SharedAsset.Colors.tintPrimary.swiftUIColor)
    }

    /// `timerColor()` returns the urgent (error) color when
    /// `Constants.totpUrgentCountdownThreshold` or fewer seconds remain.
    @Test
    func timerColor_urgent() {
        // 5 seconds remain: timeIntervalSinceReferenceDate=25, period=30 → 30-25=5 <= 7
        let subject = TOTPCountdownTimer(
            timeProvider: MockTimeProvider(.mockTime(Date(timeIntervalSinceReferenceDate: 25))),
            timerInterval: 60,
            totpCode: .init(
                code: "123456",
                codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                period: 30,
            ),
            onExpiration: nil,
        )
        #expect(subject.timerColor() == SharedAsset.Colors.error.swiftUIColor)
    }
}
