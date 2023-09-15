import SwiftUI

// MARK: - PasswordStrengthIndicator

/// A horizontal bar that changes color to indicate the strength of an entered password.
///
struct PasswordStrengthIndicator: View {
    // MARK: Properties

    /// The minimum password length.
    var minimumPasswordLength: Int

    // MARK: View

    var body: some View {
        VStack {
            HStack {
                Text(
                    Localizations.important +
                        Localizations.yourMasterPasswordCannotBeRecoveredIfYouForgetItXCharactersMinimum(
                            minimumPasswordLength
                        )
                )
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .font(.system(.footnote))

                Spacer()
            }

            RoundedRectangle(cornerRadius: 2)
                .frame(height: 8)
                .foregroundColor(Color(asset: Asset.Colors.separatorOpaque))
        }
        .padding(.bottom, 16)
    }
}
