import BitwardenResources
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

            ContentBlock(dividerLeadingPadding: 48) {
                rowView(
                    image: Asset.Images.lightbulb24,
                    title: Localizations.createAHint,
                    subtitle: Localizations.yourHintWillBeSentToYouViaEmailWhenYouRequestIt
                )

                rowView(
                    image: Asset.Images.pencil24,
                    title: Localizations.writeYourPasswordDown,
                    subtitle: Localizations.beCarefulToKeepYourWrittenPasswordSomewhereSecretAndSafe
                )
            }
        }
        .scrollView()
        .navigationBar(title: Localizations.preventAccountLockout, titleDisplayMode: .inline)
        .toolbar {
            closeToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private

    /// The main instructions.
    private var instructionsView: some View {
        VStack(spacing: 8) {
            Text(Localizations.neverLoseAccessToYourVault)
                .styleGuide(.title2, weight: .semibold)
                .multilineTextAlignment(.center)

            Text(Localizations.theBestWayToMakeSureYouCanAlwaysAccessYourAccountIsToSetUpSafeguardsFromTheStart)
                .styleGuide(.body)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        .padding(.top, 8)
    }

    /// Returns a view for displaying a row of content within the view.
    ///
    /// - Parameters:
    ///   - image: The image to display on the leading edge of the title and subtitle.
    ///   - title: The title text to display in the row.
    ///   - subtitle: The subtitle text to display in the row.
    /// - Returns: A view for displaying a row of content in the view.
    ///
    @ViewBuilder
    private func rowView(
        image: ImageAsset,
        title: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(decorative: image)
                .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .styleGuide(.body, weight: .semibold)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                if let subtitle {
                    Text(subtitle)
                        .styleGuide(.subheadline)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                }
            }
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
