import BitwardenResources
import SwiftUI

// MARK: - ImportLoginsSuccessView

/// A view that informs the user that importing logins was successful.
///
struct ImportLoginsSuccessView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, Void, ImportLoginsSuccessEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.devices,
                style: .mediumImage,
                title: Localizations.importSuccessful,
                message: Localizations.manageYourLoginsFromAnywhereWithBitwardenToolsForWebAndDesktop
            )

            ContentBlock(dividerLeadingPadding: 48) {
                rowView(
                    image: Asset.Images.puzzle24,
                    title: Localizations.downloadTheBrowserExtension,
                    subtitle: Localizations
                        .goToBitwardenToIntegrateBitwardenIntoYourFavoriteBrowserForASeamlessExperience
                )

                rowView(
                    image: Asset.Images.desktop24,
                    title: Localizations.useTheWebApp,
                    subtitle: Localizations.logInAtBitwardenToEasilyManageYourAccountAndUpdateSettings
                )

                rowView(
                    image: Asset.Images.shield24,
                    title: Localizations.autofillPasswords,
                    subtitle: Localizations.setUpAutofillOnAllYourDevicesToLoginWithASingleTapAnywhere
                )
            }

            AsyncButton(Localizations.gotIt) {
                await store.perform(.dismiss)
            }
            .buttonStyle(.primary())
        }
        .padding(.top, 12)
        .scrollView()
        .navigationBar(title: Localizations.bitwardenTools, titleDisplayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeToolbarButton {
                    Task {
                        await store.perform(.dismiss)
                    }
                }
            }
        }
    }

    // MARK: Private

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
                    .styleGuide(.body, weight: .bold)
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

// MARK: - Previews

#if DEBUG
#Preview {
    ImportLoginsSuccessView(store: Store(processor: StateProcessor()))
        .navStackWrapped
}
#endif
