import BitwardenResources
import SwiftUI

// MARK: - AppearanceView

/// A view for configuring appearance settings.
///
struct AppearanceView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<AppearanceState, AppearanceAction, AppearanceEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 8) {
            language

            theme

            webSiteIconsToggle
        }
        .scrollView()
        .navigationBar(title: Localizations.appearance, titleDisplayMode: .inline)
        .task {
            await store.perform(.loadData)
        }
    }

    // MARK: Private views

    /// The language picker view
    private var language: some View {
        Button {
            store.send(.languageTapped)
        } label: {
            BitwardenField(
                title: Localizations.language,
                footer: Localizations.languageChangeRequiresAppRestart
            ) {
                Text(store.state.currentLanguage.title)
                    .styleGuide(.body)
                    .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
                    .multilineTextAlignment(.leading)
            } accessoryContent: {
                Asset.Images.chevronDown24.swiftUIImage
                    .imageStyle(.rowIcon)
            }
        }
    }

    /// The application's color theme picker view
    private var theme: some View {
        BitwardenMenuField(
            title: Localizations.theme,
            footer: Localizations.themeDescription,
            accessibilityIdentifier: "ThemeChooser",
            options: AppTheme.allCases,
            selection: store.binding(
                get: \.appTheme,
                send: AppearanceAction.appThemeChanged
            )
        )
    }

    /// The show website icons toggle.
    private var webSiteIconsToggle: some View {
        BitwardenToggle(
            footer: Localizations.showWebsiteIconsDescription,
            isOn: store.binding(
                get: \.isShowWebsiteIconsToggleOn,
                send: AppearanceAction.toggleShowWebsiteIcons
            ),
            accessibilityIdentifier: "ShowWebsiteIconsSwitch"
        ) {
            HStack(spacing: 8) {
                Text(Localizations.showWebsiteIcons)

                Button {
                    openURL(ExternalLinksConstants.websiteIconsHelp)
                } label: {
                    Asset.Images.questionCircle16.swiftUIImage
                        .scaledFrame(width: 16, height: 16)
                        .accessibilityLabel(Localizations.learnMore)
                }
                .buttonStyle(.fieldLabelIcon)
            }
        }
        .contentBlock()
    }
}

// MARK: Previews

#Preview {
    AppearanceView(store: Store(processor: StateProcessor(state: AppearanceState())))
}
