import SwiftUI

// MARK: - AppearanceView

/// A view for configuring appearance settings.
///
struct AppearanceView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<AppearanceState, AppearanceAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            language

            theme

            defaultDarkTheme

            webSiteIconsToggle
        }
        .scrollView()
        .navigationBar(title: Localizations.appearance, titleDisplayMode: .inline)
    }

    // MARK: Private views

    /// The language picker view
    private var language: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsListItem(
                Localizations.language,
                hasDivider: false
            ) {
                store.send(.languageTapped)
            } trailingContent: {
                Text(Localizations.defaultSystem) // TODO: BIT-1185 Dynamic value
            }
            .cornerRadius(10)

            Text(Localizations.languageChangeRequiresAppRestart)
                .styleGuide(.subheadline)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
    }

    /// The application's color theme picker view
    private var theme: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsListItem(
                Localizations.theme,
                hasDivider: false
            ) {
                store.send(.themeButtonTapped)
            } trailingContent: {
                Text(store.state.appTheme.title)
            }
            .cornerRadius(10)

            Text(Localizations.themeDescription)
                .styleGuide(.subheadline)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
    }

    /// The default dark mode color theme picker view
    private var defaultDarkTheme: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsListItem(
                Localizations.defaultDarkTheme,
                hasDivider: false
            ) {
                store.send(.defaultDarkThemeChanged)
            } trailingContent: {
                Text(Localizations.dark)
            }
            .cornerRadius(10)

            Text(Localizations.defaultDarkThemeDescriptionLong)
                .styleGuide(.subheadline)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
    }

    /// The show website icons toggle.
    private var webSiteIconsToggle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: store.binding(
                get: \.isShowWebsiteIconsToggleOn,
                send: AppearanceAction.toggleShowWebsiteIcons
            )) {
                Text(Localizations.showWebsiteIcons)
            }
            .toggleStyle(.bitwarden)
            .styleGuide(.body)

            Text(Localizations.showWebsiteIconsDescription)
                .styleGuide(.subheadline)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
        .padding(.bottom, 12)
    }
}

// MARK: Previews

#Preview {
    AppearanceView(store: Store(processor: StateProcessor(state: AppearanceState())))
}
