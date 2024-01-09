import SwiftUI

// MARK: - TOTPCountdownTimer

/// A countdown timer for a TOTP Code.
///     Used to manage the state for a `TOTPCountdownTimerView`.
///
class TOTPCountdownTimer: ObservableObject {
    // MARK: Public Properties

    /// A `@Published` string representing the number of seconds remaining for a TOTP code.
    ///
    @Published var displayTime: String?

    /// A closure to call on expiration
    ///
    var onExpiration: (() -> Void)?

    /// The countdown remainder calculated relative to the current time.
    ///     Expressed as a decimal value between 0 and 1.
    ///
    var remainingFraction: CGFloat {
        CGFloat(secondsRemaining) / CGFloat(period)
    }

    // MARK: Private Properties

    /// The date when the code was first generated.
    ///
    private let calculationDate: Date

    /// The period used to calculate the countdown.
    ///
    private let period: Int

    /// The countdown remainder calculated relative to the current time.
    ///
    private var secondsRemaining: Int {
        remainingSeconds()
    }

    /// The timer responsible for updating the countdown.
    ///
    private var timer: Timer?

    /// Initializes a new countdown timer
    ///
    /// - Parameters
    ///   - totpCode: The code used to calculate the time remaining.
    ///   - onExpiration: A closure to call on timer expiration.
    ///
    init(
        totpCode: TOTPCode,
        onExpiration: (() -> Void)?
    ) {
        period = Int(totpCode.period)
        calculationDate = totpCode.date
        self.onExpiration = onExpiration
        displayTime = "\(secondsRemaining)"
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { _ in
                self.updateCountdown()
            }
        )
    }

    /// Updates the countdown timer value.
    ///
    private func updateCountdown() {
        displayTime = "\(secondsRemaining)"
        let elapsedTimeSinceCalculation = calculationDate.timeIntervalSinceNow * -1.0
        let isOlderThanInterval = elapsedTimeSinceCalculation >= Double(period)
        if secondsRemaining > remainingSeconds(for: calculationDate) || isOlderThanInterval {
            onExpiration?()
            timer?.invalidate()
            timer = nil
        }
    }

    /// Calculates the seconds remaining before an update is needed.
    ///
    /// - Parameter date: The date used to calculate the remaining seconds.
    ///
    private func remainingSeconds(for date: Date = Date()) -> Int {
        period - (Int(date.timeIntervalSinceReferenceDate) % period)
    }
}
