import SwiftUI

// MARK: - TOTPCountdownTimerView

/// A circular countdown timer view that marks the time remaining for a TOTPCode.
///
struct TOTPCountdownTimerView: View {
    /// The TOTPCode used to generate the countdown
    ///
    let totpCode: TOTPCode

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
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        }
        .padding(6)
        .background {
            CircularProgressShape(progress: timer.remainingFraction, clockwise: true)
                .stroke(lineWidth: 3)
                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
    }

    /// Initializes the view for a TOTPCode and a timer expiration handler.
    ///
    /// - Parameters:
    ///   - totpCode: The code that the timer represents.
    ///   - onExpiration: A closure called when the code expires.
    ///
    init(totpCode: TOTPCode, onExpiration: (() -> Void)?) {
        self.totpCode = totpCode
        timer = .init(totpCode: totpCode, onExpiration: onExpiration)
    }
}
