import SwiftUI

// MARK: - PreventAccountLockView

/// A view that presents the user with information about how to prevent their account from getting locked.
///
struct PreventAccountLockView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, PreventAccountLockAction, Void>

    // MARK: View

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                instructionsView

                hintInstructionsView

                writeDownInstructions
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .scrollView()
        .navigationBar(title: Localizations.preventAccountLockout, titleDisplayMode: .inline)
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
                Text(Localizations.neverLoseAccessToYourVault)
                    .styleGuide(.title3, weight: .semibold)

                Text(Localizations.theBestWayToMakeSureYouCanAlwaysAccessYourAccountIsToSetUpSafeguardsFromTheStart)
                    .styleGuide(.body)
            }
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(24)

            Divider()
        }
    }

    /// The hint instructions.
    private var hintInstructionsView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Image(decorative: Asset.Images.lightbulb)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Asset.Colors.iconSecondary.swiftUIColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Localizations.createAHint)
                        .styleGuide(.headline, weight: .semibold)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                    Text(Localizations.yourHintWillBeSentToYouViaEmailWhenYouRequestIt)
                        .styleGuide(.subheadline)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)

            Divider().padding(.leading, 68)
        }
    }

    /// The writing down instructions.
    private var writeDownInstructions: some View {
        HStack(spacing: 20) {
            Image(decorative: Asset.Images.pencil)
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(Asset.Colors.iconSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localizations.writeYourPasswordDown)
                    .styleGuide(.headline, weight: .semibold)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                Text(Localizations.beCarefulToKeepYourWrittenPasswordSomewhereSecretAndSafe)
                    .styleGuide(.subheadline)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    PreventAccountLockView(
        store: Store(
            processor: StateProcessor(
                state: ()
            )
        )
    )
}
#endif
