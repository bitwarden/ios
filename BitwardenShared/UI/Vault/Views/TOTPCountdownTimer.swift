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
    private let totpCodeMode: TOTPCodeModel

    /// A model to provide time to calculate the countdown.
    ///
    private var timeProvider: any TimeProvider

    /// The timer responsible for updating the countdown.
    ///
    private var timer: Timer?

    // MARK: Private Derived Properties

    /// The period used to calculate the countdown.
    ///
    private var period: Int {
        Int(totpCodeMode.period)
    }

    /// The countdown remainder calculated relative to the current time.
    ///
    private var secondsRemaining: Int {
        TOTPExpirationCalculator.remainingSeconds(for: timeProvider.presentTime, using: period)
    }

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
        totpCode: TOTPCodeModel,
        onExpiration: (() -> Void)?
    ) {
        totpCodeMode = totpCode
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

    /// Invalidate and remove the timer on deinit.
    ///
    deinit {
        cleanup()
    }

    /// Invalidates and removes the timer for expiration management.
    ///
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }

    /// Updates the countdown timer value.
    ///
    private func updateCountdown() {
        displayTime = "\(secondsRemaining)"
        if TOTPExpirationCalculator.hasCodeExpired(
            totpCodeMode,
            timeProvider: timeProvider
        ) {
            onExpiration?()
            timer?.invalidate()
            timer = nil
        }
    }
}
