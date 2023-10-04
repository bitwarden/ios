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
        VStack(alignment: .leading) {
            Text(Localizations.important + ": ")
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .font(.system(.footnote).bold()) +
                Text(Localizations.yourMasterPasswordCannotBeRecoveredIfYouForgetItXCharactersMinimum(
                    minimumPasswordLength
                ))
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .font(.system(.footnote))

            RoundedRectangle(cornerRadius: 2)
                .frame(height: 4)
                .foregroundColor(Color(asset: Asset.Colors.separatorOpaque))
                .padding(.top, 4)
        }
        .padding(.bottom, 16)
    }
}
