import SwiftUI

// MARK: - OtherSettingsView

/// A view that allows users to configure miscellaneous settings.
///
struct OtherSettingsView: View {
    // MARK: Properties

    @ObservedObject var store: Store<OtherSettingsState, OtherSettingsAction, Void>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            allowSyncOnRefresh

            syncNow

            clearClipboard

            connectToWatch
        }
        .scrollView()
        .navigationBar(title: Localizations.other, titleDisplayMode: .inline)
    }

    // MARK: Private views

    /// The allow sync on refresh toggle and description.
    private var allowSyncOnRefresh: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: store.binding(
                get: \.isAllowSyncOnRefreshToggleOn,
                send: OtherSettingsAction.toggleAllowSyncOnRefresh
            )) {
                Text(Localizations.enableSyncOnRefresh)
            }
            .toggleStyle(.bitwarden)
            .font(.styleGuide(.body))

            Text(Localizations.enableSyncOnRefreshDescription)
                .font(.styleGuide(.footnote))
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .multilineTextAlignment(.leading)
        }
    }

    /// The clear clipboard button and description.
    private var clearClipboard: some View {
        VStack(alignment: .leading, spacing: 5) {
            SettingsListItem(
                Localizations.clearClipboard,
                hasDivider: false
            ) {} trailingContent: {
                Text(Localizations.fiveMinutes) // TODO: BIT-1183 Dynamic value
            }
            .cornerRadius(10)

            Text(Localizations.clearClipboardDescription)
                .font(.styleGuide(.footnote))
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .multilineTextAlignment(.leading)
        }
    }

    /// The connect to watch toggle.
    private var connectToWatch: some View {
        Toggle(isOn: store.binding(
            get: \.isConnectToWatchToggleOn,
            send: OtherSettingsAction.toggleConnectToWatch
        )) {
            Text(Localizations.connectToWatch)
        }
        .toggleStyle(.bitwarden)
        .font(.styleGuide(.body))
        .padding(.top, 8)
    }

    /// The sync now button and last synced description.
    private var syncNow: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {} label: {
                Text(Localizations.syncNow)
            }
            .buttonStyle(.tertiary())

            HStack(spacing: 0) {
                Text(Localizations.lastSync + " ")
                Text("5/14/2023 4:52 PM") // TODO: BIT-1182 Dynamic date value
            }
            .font(.styleGuide(.footnote))
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .multilineTextAlignment(.leading)
        }
    }
}

// MARK: Previews

struct OtherSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OtherSettingsView(store: Store(processor: StateProcessor(state: OtherSettingsState())))
    }
}
