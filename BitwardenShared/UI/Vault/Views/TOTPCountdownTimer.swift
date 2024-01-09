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

    /// A model to provide time to calculate the countdown.
    ///
    private var timeProvider: any TimeProvider

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
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///         Used to calculate time remaining for a present TOTP code.
    ///   - totpCode: The code used to calculate the time remaining.
    ///   - onExpiration: A closure to call on timer expiration.
    ///
    init(
        timeProvider: any TimeProvider,
        totpCode: TOTPCodeState,
        onExpiration: (() -> Void)?
    ) {
        period = Int(totpCode.period)
        calculationDate = totpCode.codeGenerationDate
        self.timeProvider = timeProvider
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
        let elapsedTimeSinceCalculation = timeProvider.timeSince(calculationDate)
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
    private func remainingSeconds(for date: Date? = nil) -> Int {
        let remainderCalculationDate = date ?? timeProvider.presentTime
        return period - (Int(remainderCalculationDate.timeIntervalSinceReferenceDate) % period)
    }
}

protocol TimeProvider: Sendable, Equatable {
    var presentTime: Date { get }
    func timeSince(_ date: Date) -> TimeInterval
}

struct CurrentTime: TimeProvider {
    var presentTime: Date {
        .now
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
