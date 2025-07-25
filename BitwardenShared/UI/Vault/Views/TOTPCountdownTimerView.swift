import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - TOTPCountdownTimerView

/// A circular countdown timer view that marks the time remaining for a TOTPCodeState.
///
struct TOTPCountdownTimerView: View {
    // MARK: Static Properties

    /// The interval at which the view should check for expirations and update the time remaining.
    ///
    static let timerInterval: TimeInterval = 0.1

    // MARK: Properties

    /// The TOTPCode used to generate the countdown
    ///
    let totpCode: TOTPCodeModel

    /// The `TOTPCountdownTimer`responsible for updating the view state.
    ///
    @ObservedObject private(set) var timer: TOTPCountdownTimer

    var body: some View {
        ZStack {
            Text("  ")
                .styleGuide(.caption2Monospaced)
                .accessibilityHidden(true)
            Text(timer.displayTime ?? "")
                .styleGuide(.caption2Monospaced, monoSpacedDigit: true)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
        }
        .padding(6)
        .background {
            CircularProgressShape(progress: timer.remainingFraction, clockwise: true)
                .stroke(lineWidth: 3)
                .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
                .animation(
                    .smooth(
                        duration: TOTPCountdownTimerView.timerInterval
                    ),
                    value: timer.remainingFraction
                )
        }
    }

    /// Initializes the view for a TOTPCodeModel and a timer expiration handler.
    ///
    /// - Parameters:
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///         Used to calculate time remaining for a present TOTP code.
    ///   - totpCode: The code that the timer represents.
    ///   - onExpiration: A closure called when the code expires.
    ///
    init(
        timeProvider: any TimeProvider,
        totpCode: TOTPCodeModel,
        onExpiration: (() -> Void)?
    ) {
        self.totpCode = totpCode
        timer = .init(
            timeProvider: timeProvider,
            timerInterval: TOTPCountdownTimerView.timerInterval,
            totpCode: totpCode,
            onExpiration: onExpiration
        )
    }
}
