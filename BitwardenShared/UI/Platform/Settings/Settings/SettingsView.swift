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
        ScrollView {
            VStack {
                settingsItems

                logoutButton
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.settings)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private views

    /// The logout button.
    private var logoutButton: some View {
        VStack {
            Button {
                store.send(.logout)
            } label: {
                Text(Localizations.logOut)
                    .font(.styleGuide(.body))
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .background(Asset.Colors.backgroundElevatedTertiary.swiftUIColor)
        .cornerRadius(10)
    }

    /// The settings items.
    private var settingsItems: some View {
        VStack(spacing: 0) {
            listItem(Localizations.accountSecurity) {}
            listItem(Localizations.autofill) {}
            listItem(Localizations.vault) {}
            listItem(Localizations.appearance) {}
            listItem(Localizations.other) {}
            listItem(Localizations.about, hasDivider: false) {}
        }
        .background(Asset.Colors.backgroundElevatedTertiary.swiftUIColor)
        .cornerRadius(10)
    }

    /// A list item.
    ///
    /// - Parameters:
    ///  - name: The name of the list item.
    ///  - hasDivider: Whether or not the list item should have a divider on the bottom.
    ///  - action: The action to perform when the list item is tapped.
    ///
    /// - Returns: The list item.
    ///
    private func listItem(
        _ name: String,
        hasDivider: Bool = true,
        _ action: @escaping () -> Void
    ) -> some View {
        Button {} label: {
            VStack(spacing: 0) {
                HStack {
                    Text(name)
                        .font(.styleGuide(.body))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(asset: Asset.Images.chevron)
                        .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                }
                .padding()

                if hasDivider {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
    }
}

// MARK: - Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(store: Store(processor: StateProcessor(state: SettingsState())))
        }
    }
}
