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

    /// If the native-create-account feature flag is on.
    let nativeCreateAccountFlow: Bool

    // MARK: View

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: nativeCreateAccountFlow ? 4 : 0
        ) {
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

            if nativeCreateAccountFlow {
                HStack {
                    HStack(spacing: 4) {
                        if passwordTextCount >= requiredTextCount {
                            Image(asset: Asset.Images.check)
                                .foregroundColor(Color(asset: Asset.Colors.loadingGreen))
                                .frame(width: 10)
                                .padding(1)
                        } else {
                            Circle()
                                .stroke(Color(.separatorOpaque), lineWidth: 2)
                                .frame(width: 10)
                                .padding(1)
                        }

                        Text("\(requiredTextCount) \(Localizations.characters)")
                            .foregroundColor(
                                passwordTextCount >= requiredTextCount ?
                                    Color(asset: Asset.Colors.loadingGreen) :
                                    Color(asset: Asset.Colors.separatorOpaque)
                            )
                            .styleGuide(.footnote, weight: .bold)
                    }

                    Spacer()

                    Text(passwordStrength.text ?? "")
                        .foregroundColor(Color(asset: passwordStrength.color))
                        .styleGuide(.footnote)
                }
                .frame(height: 10)
            } else {
                if let text = passwordStrength.text {
                    Text(text)
                        .foregroundColor(Color(asset: passwordStrength.color))
                        .styleGuide(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: Initialization

    /// Initialize a `PasswordStrengthIndicator`.
    ///
    /// - Parameter passwordStrengthScore: The scoring metric representing the strength of the
    ///     entered password.
    ///
    init(
        passwordStrengthScore: UInt8? = nil,
        passwordTextCount: Int = 0,
        requiredTextCount: Int = 0,
        nativeCreateAccountFlow: Bool = false
    ) {
        passwordStrength = PasswordStrength(score: passwordStrengthScore)
        self.passwordTextCount = passwordTextCount
        self.requiredTextCount = requiredTextCount
        self.nativeCreateAccountFlow = nativeCreateAccountFlow
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
                passwordStrengthScore: nil,
                passwordTextCount: 0
            )

            ForEach(UInt8(0) ... UInt8(4), id: \.self) { score in
                PasswordStrengthIndicator(
                    passwordStrengthScore: score,
                    passwordTextCount: 0
                )
            }
        }
        .padding()
    }
}
#endif
