import SwiftUI

// MARK: - OtherSettingsView

/// A view that allows users to configure miscellaneous settings.
///
struct OtherSettingsView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            allowSyncOnRefresh

            syncNow

            VStack(alignment: .leading, spacing: 8) {
                clearClipboard

                if store.state.shouldShowConnectToWatchToggle {
                    connectToWatch
                }
            }
        }
        .scrollView(padding: 12)
        .navigationBar(title: Localizations.other, titleDisplayMode: .inline)
        .toast(store.binding(
            get: \.toast,
            send: OtherSettingsAction.toastShown
        ))
        .task {
            await store.perform(.streamLastSyncTime)
        }
        .task {
            await store.perform(.loadInitialValues)
        }
    }

    // MARK: Private views

    /// The allow sync on refresh toggle and description.
    private var allowSyncOnRefresh: some View {
        BitwardenToggle(
            Localizations.enableSyncOnRefresh,
            isOn: store.binding(
                get: \.isAllowSyncOnRefreshToggleOn,
                send: OtherSettingsAction.toggleAllowSyncOnRefresh
            ),
            accessibilityIdentifier: "SyncOnRefreshSwitch"
        ) {
            Text(Localizations.enableSyncOnRefreshDescription)
                .styleGuide(.footnote)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
        .contentBlock()
    }

    /// The clear clipboard button and description.
    private var clearClipboard: some View {
        BitwardenMenuField(
            title: Localizations.clearClipboard,
            footer: Localizations.clearClipboardDescription,
            accessibilityIdentifier: "ClearClipboardChooser",
            options: ClearClipboardValue.allCases,
            selection: store.binding(
                get: \.clearClipboardValue,
                send: OtherSettingsAction.clearClipboardValueChanged
            )
        )
    }

    /// The connect to watch toggle.
    private var connectToWatch: some View {
        BitwardenToggle(
            Localizations.connectToWatch,
            isOn: store.binding(
                get: \.isConnectToWatchToggleOn,
                send: OtherSettingsAction.toggleConnectToWatch
            )
        )
        .contentBlock()
    }

    /// The sync now button and last synced description.
    private var syncNow: some View {
        VStack(alignment: .leading, spacing: 5) {
            AsyncButton {
                await store.perform(.syncNow)
            } label: {
                Text(Localizations.syncNow)
            }
            .buttonStyle(.secondary())
            .accessibilityIdentifier("SyncNowButton")

            Group {
                if let lastSyncDate = store.state.lastSyncDate {
                    FormattedDateTimeView(label: Localizations.lastSync, separator: "", date: lastSyncDate)
                        .accessibilityIdentifier("LastSyncLabel")
                } else {
                    Text(Localizations.lastSync + " --")
                        .accessibilityIdentifier("LastSyncLabel")
                }
            }
            .padding(.leading, 16)
            .styleGuide(.footnote)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .multilineTextAlignment(.leading)
        }
    }
}

// MARK: Previews

#Preview {
    OtherSettingsView(store: Store(processor: StateProcessor(state: OtherSettingsState())))
}
