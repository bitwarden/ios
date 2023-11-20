import SwiftUI

// MARK: - OtherView

struct OtherView: View {
    // MARK: Properties

    @ObservedObject var store: Store<OtherState, OtherAction, Void>

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
            ToggleView(
                isOn: store.binding(
                    get: \.isAllowSyncOnRefreshToggleOn,
                    send: OtherAction.toggleAllowSyncOnRefresh
                ),
                description: Localizations.enableSyncOnRefresh
            )

            Text(Localizations.enableSyncOnRefreshDescription)
                .font(.styleGuide(.footnote))
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .multilineTextAlignment(.leading)
        }
    }

    /// The clear clipboard button and description.
    private var clearClipboard: some View {
        VStack(alignment: .leading, spacing: 5) {
            SettingsListItem(Localizations.clearClipboard) {} trailingContent: {
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
        ToggleView(
            isOn: store.binding(
                get: \.isConnectToWatchToggleOn,
                send: OtherAction.toggleConnectToWatch
            ),
            description: Localizations.connectToWatch
        )
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

struct OtherView_Previews: PreviewProvider {
    static var previews: some View {
        OtherView(store: Store(processor: StateProcessor(state: OtherState())))
    }
}
