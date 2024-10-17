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
        VStack(spacing: 24) {
            instructionsView

            VStack(spacing: 0) {
                hintInstructionsView

                writeDownInstructions
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .scrollView()
        .navigationBar(title: Localizations.preventAccountLockout, titleDisplayMode: .inline)
        .toolbar {
            closeToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private views

    /// The main instructions.
    private var instructionsView: some View {
        VStack(spacing: 8) {
            Text(Localizations.neverLoseAccessToYourVault)
                .styleGuide(.title2, weight: .semibold)

            Text(Localizations.theBestWayToMakeSureYouCanAlwaysAccessYourAccountIsToSetUpSafeguardsFromTheStart)
                .styleGuide(.body)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .padding(.top, 8)
    }

    /// The hint instructions.
    private var hintInstructionsView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(decorative: Asset.Images.lightbulb24)
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
            .padding(12)

            Divider().padding(.leading, 48)
        }
    }

    /// The writing down instructions.
    private var writeDownInstructions: some View {
        HStack(spacing: 12) {
            Image(decorative: Asset.Images.pencil24)
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
        .padding(12)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    NavigationView {
        PreventAccountLockView(
            store: Store(
                processor: StateProcessor(
                    state: ()
                )
            )
        )
    }
}
#endif
