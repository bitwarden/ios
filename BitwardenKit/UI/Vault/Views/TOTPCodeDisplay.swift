import BitwardenResources
import SwiftUI

// MARK: - TOTPCodeDisplay

/// A view that displays the current TOTP code, a countdown timer, and — when close
/// to expiry and the setting is enabled — a preview of the next code.
///
public struct TOTPCodeDisplay: View {
    // MARK: Properties

    /// The current TOTP code to display.
    ///
    let currentCode: TOTPCodeModel

    /// The upcoming TOTP code to preview when close to expiry, if available.
    ///
    let nextCode: TOTPCodeModel?

    /// Whether to show the next code preview when the current code is about to expire.
    ///
    let showNextTOTPCode: Bool

    /// The timer that drives both the countdown ring and the next-code visibility check.
    ///
    @ObservedObject private var timer: TOTPCountdownTimer

    // MARK: View

    public var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(currentCode.displayCode)
                    .styleGuide(.bodyMonospaced, weight: .regular, monoSpacedDigit: true)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("ItemTOTPCodeLabel")
                if timer.secondsRemaining <= Constants.nextTOTPCodePreviewThreshold,
                   let nextCode,
                   showNextTOTPCode {
                    Text(nextCode.displayCode)
                        .styleGuide(.caption2Monospaced, monoSpacedDigit: true)
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .accessibilityLabel(Localizations.nextCode)
                }
            }
            TOTPCountdownTimerView(
                timer: timer,
                totpCode: currentCode,
            )
        }
    }

    // MARK: Initialization

    /// Initializes the view.
    ///
    /// - Parameters:
    ///   - currentCode: The current TOTP code to display.
    ///   - nextCode: The upcoming TOTP code to preview when close to expiry, if available.
    ///   - showNextTOTPCode: Whether to show the next code preview when the current code is about to expire.
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///
    public init(
        currentCode: TOTPCodeModel,
        nextCode: TOTPCodeModel?,
        showNextTOTPCode: Bool,
        timeProvider: any TimeProvider,
    ) {
        self.currentCode = currentCode
        self.nextCode = nextCode
        self.showNextTOTPCode = showNextTOTPCode
        timer = TOTPCountdownTimer(
            timeProvider: timeProvider,
            timerInterval: TOTPCountdownTimerView.timerInterval,
            totpCode: currentCode,
            onExpiration: nil,
        )
    }
}

#if DEBUG
#Preview("Current code only") {
    TOTPCodeDisplay(
        currentCode: TOTPCodeModel(
            code: "123456",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        nextCode: nil,
        showNextTOTPCode: false,
        timeProvider: PreviewTimeProvider(),
    )
}

#Preview("Next code visible") {
    TOTPCodeDisplay(
        currentCode: TOTPCodeModel(
            code: "123456",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        nextCode: TOTPCodeModel(
            code: "789012",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        showNextTOTPCode: true,
        timeProvider: PreviewTimeProvider(
            fixedDate: Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 22),
        ),
    )
}

#Preview("Next code hidden (setting off)") {
    TOTPCodeDisplay(
        currentCode: TOTPCodeModel(
            code: "123456",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        nextCode: TOTPCodeModel(
            code: "789012",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        showNextTOTPCode: false,
        timeProvider: PreviewTimeProvider(
            fixedDate: Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 22),
        ),
    )
}

#Preview("Urgent timer color") {
    TOTPCodeDisplay(
        currentCode: TOTPCodeModel(
            code: "123456",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        nextCode: TOTPCodeModel(
            code: "789012",
            codeGenerationDate: Date(year: 2023, month: 12, day: 31),
            period: 30,
        ),
        showNextTOTPCode: true,
        timeProvider: PreviewTimeProvider(
            fixedDate: Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 25),
        ),
    )
}
#endif
