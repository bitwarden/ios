import BitwardenResources
import SwiftUI

// MARK: - PasswordStrengthIndicator

/// A horizontal bar that changes color to indicate the strength of an entered password.
///
struct PasswordStrengthIndicator: View {
    // MARK: Properties

    /// The password's strength.
    let passwordStrength: PasswordStrength

    /// The current count of characters in the password.
    let passwordTextCount: Int

    /// The required text count for the password
    let requiredTextCount: Int

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(asset: SharedAsset.Colors.strokeDivider))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(asset: passwordStrength.color))
                        .frame(width: geometry.size.width * passwordStrength.strengthPercent, alignment: .leading)
                        .animation(.easeIn, value: passwordStrength.strengthPercent)
                }
                .frame(height: 4)
            }

            HStack {
                HStack(spacing: 4) {
                    if passwordTextCount >= requiredTextCount {
                        Image(asset: Asset.Images.check12)
                            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .padding(.leading, 1)
                    } else {
                        Circle()
                            .stroke(SharedAsset.Colors.iconPrimary.swiftUIColor, lineWidth: 2)
                            .frame(width: 10, height: 10)
                            .padding(.leading, 1)
                    }

                    Text(Localizations.xCharacters(requiredTextCount))
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .styleGuide(.footnote, weight: .bold)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                }

                Spacer()

                Text(passwordStrength.text ?? "")
                    .foregroundColor(Color(asset: passwordStrength.color))
                    .styleGuide(.footnote)
            }
        }
    }

    /// Initialize a `PasswordStrengthIndicator`.
    ///
    /// - Parameters:
    ///   - passwordStrengthScore: The scoring metric representing the strength of the
    ///     entered password. The value's range is 0-4. Defaults to `nil`.
    ///   - passwordTextCount: The current length of the entered password.
    ///   - requiredTextCount: The required minimum length for the password.
    ///
    init(
        passwordStrengthScore: UInt8? = nil,
        passwordTextCount: Int = 0,
        requiredTextCount: Int = 0
    ) {
        passwordStrength = PasswordStrength(score: passwordStrengthScore)
        self.passwordTextCount = passwordTextCount
        self.requiredTextCount = requiredTextCount
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
                color = SharedAsset.Colors.statusWeak1
                text = Localizations.weak
            case 2:
                color = SharedAsset.Colors.statusWeak2
                text = Localizations.weak
            case 3:
                color = SharedAsset.Colors.statusGood
                text = Localizations.good
            case 4:
                color = SharedAsset.Colors.statusStrong
                text = Localizations.strong
            default:
                // Provide the initial color when not visible so the color isn't animated when the
                // first segment appears.
                color = SharedAsset.Colors.statusWeak1
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
                passwordStrengthScore: nil,
                passwordTextCount: 0
            )

            ForEach(UInt8(0) ... UInt8(4), id: \.self) { score in
                PasswordStrengthIndicator(
                    passwordStrengthScore: score,
                    passwordTextCount: 0
                )
            }

            PasswordStrengthIndicator(
                passwordStrengthScore: UInt8(4),
                passwordTextCount: 0
            )

            PasswordStrengthIndicator(
                passwordStrengthScore: UInt8(12),
                passwordTextCount: 5,
                requiredTextCount: 12
            )
        }
        .padding()
    }
}
#endif
