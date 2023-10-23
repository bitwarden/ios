import SwiftUI

/// A view containing the top-level list of settings.
///
struct SettingsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SettingsState, SettingsAction, Void>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Button {
                    store.send(.logout)
                } label: {
                    Text(Localizations.logOut)
                        .font(.styleGuide(.body))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Asset.Colors.backgroundElevatedTertiary.swiftUIColor)
                        .cornerRadius(10)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.settings)
        .navigationBarTitleDisplayMode(.large)
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
