import SwiftUI

// MARK: - MasterPasswordGuidanceView

/// A view that presents the user with guidance about how to create a strong master password.
///
struct MasterPasswordGuidanceView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, MasterPasswordGuidanceAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                instructionsView

                detailedInstructionsView
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            passwordGeneratorButton
        }
        .scrollView()
        .navigationBar(title: Localizations.masterPasswordHelp, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private views

    /// The main instructions.
    private var instructionsView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localizations.whatMakesAPasswordStrong)
                    .styleGuide(.title3, weight: .semibold)

                Text(Localizations.strongPasswordDescriptionLong)
                    .styleGuide(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(24)

            Divider()
        }
    }

    /// The detailed instructions.
    private var detailedInstructionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.theStrongestPasswordsAreUsually)
                .styleGuide(.callout, weight: .semibold)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.bottom, 8)

            bulletPoint(text: Localizations.twelveOrMoreCharacters)
            bulletPoint(text: Localizations.randomAndComplexUsingNumbersAndSpecialCharacters)
            bulletPoint(text: Localizations.totallyDifferentFromYourOtherPasswords)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    /// The password generator button.
    private var passwordGeneratorButton: some View {
        Button {
            store.send(.generatePasswordPressed)
        } label: {
            HStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image(decorative: Asset.Images.generate)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Asset.Colors.iconSecondary.swiftUIColor)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(Localizations.useTheGeneratorToCreateAStrongUniquePassword)
                            .styleGuide(.body, weight: .semibold)
                            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                            .multilineTextAlignment(.leading)

                        Text(Localizations.tryItOut)
                            .styleGuide(.subheadline)
                            .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(decorative: Asset.Images.chevronRight16)
                    .foregroundStyle(Asset.Colors.iconPrimary.swiftUIColor)
            }
            .padding(16)
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Create a line of text with a bullet point in front of it.
    ///
    private func bulletPoint(text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")

            Text(text)
        }
        .styleGuide(.subheadline)
        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    MasterPasswordGuidanceView(
        store: Store(
            processor: StateProcessor(
                state: ()
            )
        )
    )
}
#endif
