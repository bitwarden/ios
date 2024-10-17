import SwiftUI

// MARK: - ImportLoginsSuccessView

/// A view that informs the user that importing logins was successful.
///
struct ImportLoginsSuccessView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, ImportLoginsSuccessAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            PageHeaderView(
                image: Asset.Images.devices,
                title: Localizations.importSuccessful,
                message: Localizations.manageYourLoginsFromAnywhereWithBitwardenToolsForWebAndDesktop
            )

            ContentBlock(dividerLeadingPadding: 48) {
                rowView(
                    image: Asset.Images.puzzle,
                    title: Localizations.downloadTheBrowserExtension,
                    subtitle: Localizations
                        .goToBitwardenToIntegrateBitwardenIntoYourFavoriteBrowserForASeamlessExperience
                )

                rowView(
                    image: Asset.Images.desktop,
                    title: Localizations.useTheWebApp,
                    subtitle: Localizations.logInAtBitwardenToEasilyManageYourAccountAndUpdateSettings
                )

                rowView(
                    image: Asset.Images.shield,
                    title: Localizations.autofillPasswords,
                    subtitle: Localizations.setUpAutofillOnAllYourDevicesToLoginWithASingleTapAnywhere
                )
            }

            Button(Localizations.gotIt) {
                store.send(.dismiss)
            }
            .buttonStyle(.primary())
        }
        .padding(.top, 8)
        .scrollView()
        .navigationBar(title: Localizations.bitwardenTools, titleDisplayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeToolbarButton {
                    store.send(.dismiss)
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
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Asset.Colors.iconSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .styleGuide(.body, weight: .bold)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

                if let subtitle {
                    Text(subtitle)
                        .styleGuide(.subheadline)
                        .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
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
