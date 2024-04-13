import SwiftUI

// MARK: - SettingsView

/// A view containing the top-level list of settings.
///
struct SettingsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SettingsState, SettingsAction, Void>

    // MARK: View

    var body: some View {
        settingsItems
            .scrollView()
            .navigationBar(title: Localizations.settings, titleDisplayMode: .large)
    }

    // MARK: Private views

    /// The chevron shown in the settings list item.
    private var chevron: some View {
        Image(asset: Asset.Images.rightAngle)
            .resizable()
            .scaledFrame(width: 12, height: 12)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
    }

    /// The settings items.
    private var settingsItems: some View {
        VStack(spacing: 0) {
            SettingsListItem(Localizations.appearance) {
                store.send(.appearancePressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("AppearanceSettingsButton")

            SettingsListItem(Localizations.about, hasDivider: false) {
                store.send(.aboutPressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("AboutSettingsButton")
        }
        .cornerRadius(10)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        SettingsView(store: Store(processor: StateProcessor(state: SettingsState())))
    }
}
#endif
