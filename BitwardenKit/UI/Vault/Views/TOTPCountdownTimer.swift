import BitwardenResources
import SwiftUI

// MARK: - TOTPCountdownTimer

/// A countdown timer for a TOTP code.
///     Used to manage the state for a `TOTPCountdownTimerView`.
///
public class TOTPCountdownTimer: ObservableObject {
    // MARK: Properties

    /// A `@Published` string representing the number of seconds remaining for a TOTP code.
    ///
    @Published var displayTime: String?

    /// A closure to call on expiration.
    ///
    var onExpiration: (() -> Void)?

    /// The countdown remainder calculated relative to the current time.
    ///     Expressed as a decimal value between 0 and 1.
    ///
    lazy var remainingFraction: CGFloat = durationFractionRemaining

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

    /// The fraction of duration remaining.
    ///
    private var durationFractionRemaining: CGFloat {
        let value = TOTPExpirationCalculator.timeRemaining(
            for: timeProvider.presentTime,
            using: TimeInterval(period),
        ) / TimeInterval(period)
        return min(max(0.0, value), 1.0)
    }

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

    // MARK: Initialization

    /// Initializes a new countdown timer.
    ///
    /// - Parameters:
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///         Used to calculate time remaining for a present TOTP code.
    ///   - timerInterval: The interval for the timer to check for expirations.
    ///   - totpCode: The code used to calculate the time remaining.
    ///   - onExpiration: A closure to call on timer expiration.
    ///
    public init(
        timeProvider: any TimeProvider,
        timerInterval: TimeInterval,
        totpCode: TOTPCodeModel,
        onExpiration: (() -> Void)?,
    ) {
        totpCodeMode = totpCode
        self.timeProvider = timeProvider
        self.onExpiration = onExpiration
        displayTime = "\(secondsRemaining)"
        timer = Timer.scheduledTimer(
            withTimeInterval: timerInterval,
            repeats: true,
            block: { [weak self] _ in
                self?.updateCountdown()
            },
        )
    }

    /// Invalidate and remove the timer on deinit.
    ///
    deinit {
        cleanup()
    }

    // MARK: Methods

    /// Invalidates and removes the timer for expiration management.
    ///
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }

    /// Returns the color to use for the countdown circle based on seconds remaining.
    ///
    public func timerColor() -> Color {
        secondsRemaining <= Constants.totpUrgentCountdownThreshold
            ? SharedAsset.Colors.danger.swiftUIColor
            : SharedAsset.Colors.tintPrimary.swiftUIColor
    }

    // MARK: Private Methods

    /// Updates the countdown timer value.
    ///
    private func updateCountdown() {
        displayTime = "\(secondsRemaining)"
        withAnimation {
            remainingFraction = CGFloat(durationFractionRemaining)
        }
        if TOTPExpirationCalculator.hasCodeExpired(
            totpCodeMode,
            timeProvider: timeProvider,
        ) {
            onExpiration?()
            timer?.invalidate()
            timer = nil
        }
    }
}
