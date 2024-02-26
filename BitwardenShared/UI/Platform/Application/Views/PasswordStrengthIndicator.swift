import SwiftUI

// MARK: - PasswordStrengthIndicator

/// A horizontal bar that changes color to indicate the strength of an entered password.
///
struct PasswordStrengthIndicator: View {
    // MARK: Properties

    /// The minimum password length.
    var minimumPasswordLength: Int

    /// The password's strength.
    let passwordStrength: PasswordStrength

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text(Localizations.important + ": ")
                    .bold() +
                    Text(Localizations.yourMasterPasswordCannotBeRecoveredIfYouForgetItXCharactersMinimum(
                        minimumPasswordLength)
                    )
            }
            .styleGuide(.footnote)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .padding(.bottom, 16)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(asset: Asset.Colors.separatorOpaque))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(asset: passwordStrength.color))
                        .frame(width: geometry.size.width * passwordStrength.strengthPercent, alignment: .leading)
                        .animation(.easeIn, value: passwordStrength.strengthPercent)
                }
                .frame(height: 4)
            }

            if let text = passwordStrength.text {
                Text(text)
                    .foregroundColor(Color(asset: passwordStrength.color))
                    .styleGuide(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Initialization

    /// Initialize a `PasswordStrengthIndicator`.
    ///
    /// - Parameters:
    ///   - minimumPasswordLength: The minimum password length.
    ///   - passwordStrengthScore: The scoring metric representing the strength of the entered password.
    ///
    init(minimumPasswordLength: Int, passwordStrengthScore: UInt8? = nil) {
        self.minimumPasswordLength = minimumPasswordLength
        passwordStrength = PasswordStrength(score: passwordStrengthScore)
    }
}

// MARK: - PasswordStrength

extension PasswordStrengthIndicator {
    /// A helper object that determines the view properties for the password strength indicator
    /// based on the password strength score.
    ///
    struct PasswordStrength {
        // MARK: Properties

        /// The color of the strength text and the indicator bar.
        let color: ColorAsset

        /// The strength text to display beneath the indicator bar.
        let text: String?

        /// The percent that the indicator bar should be filled.
        let strengthPercent: CGFloat

        // MARK: Initialization

        /// Initialize `PasswordStrength` with the password score.
        ///
        /// - Parameter score: The password score indicating the strength of the password. The
        ///     value's range is 0-4.
        ///
        init(score: UInt8?) {
            switch score {
            case 0, 1:
                color = Asset.Colors.loadingRed
                text = Localizations.weak
            case 2:
                color = Asset.Colors.loadingOrange
                text = Localizations.weak
            case 3:
                color = Asset.Colors.loadingBlue
                text = Localizations.good
            case 4:
                color = Asset.Colors.loadingGreen
                text = Localizations.strong
            default:
                // Provide the initial color when not visible so the color isn't animated when the
                // first segment appears.
                color = Asset.Colors.loadingRed
                text = nil
            }

            if let score, score <= 4 {
                strengthPercent = CGFloat(score + 1) / 5
            } else {
                strengthPercent = 0
            }
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    ScrollView {
        VStack {
            PasswordStrengthIndicator(
                minimumPasswordLength: Constants.minimumPasswordCharacters,
                passwordStrengthScore: nil
            )

            ForEach(UInt8(0) ... UInt8(4), id: \.self) { score in
                PasswordStrengthIndicator(
                    minimumPasswordLength: Constants.minimumPasswordCharacters,
                    passwordStrengthScore: score
                )
            }
        }
        .padding()
    }
}
#endif
