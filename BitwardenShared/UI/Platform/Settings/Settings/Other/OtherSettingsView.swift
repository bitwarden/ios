import SwiftUI

// MARK: - OtherSettingsView

/// A view that allows users to configure miscellaneous settings.
///
struct OtherSettingsView: View {
    // MARK: Properties

    @ObservedObject var store: Store<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect>

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
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: store.binding(
                get: \.isAllowSyncOnRefreshToggleOn,
                send: OtherSettingsAction.toggleAllowSyncOnRefresh
            )) {
                Text(Localizations.enableSyncOnRefresh)
            }
            .toggleStyle(.bitwarden)
            .styleGuide(.body)

            Text(Localizations.enableSyncOnRefreshDescription)
                .styleGuide(.footnote)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .multilineTextAlignment(.leading)
        }
    }

    /// The clear clipboard button and description.
    private var clearClipboard: some View {
        VStack(alignment: .leading, spacing: 5) {
            SettingsMenuField(
                title: Localizations.clearClipboard,
                options: ClearClipboardValue.allCases,
                hasDivider: false,
                selection: store.binding(
                    get: \.clearClipboardValue,
                    send: OtherSettingsAction.clearClipboardValueChanged
                )
            )
            .cornerRadius(10)

            Text(Localizations.clearClipboardDescription)
                .styleGuide(.footnote)
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
        .styleGuide(.body)
        .padding(.top, 8)
    }

    /// The sync now button and last synced description.
    private var syncNow: some View {
        VStack(alignment: .leading, spacing: 5) {
            AsyncButton {
                await store.perform(.syncNow)
            } label: {
                Text(Localizations.syncNow)
            }
            .buttonStyle(.tertiary())

            Group {
                if let lastSyncDate = store.state.lastSyncDate {
                    FormattedDateTimeView(label: Localizations.lastSync, separator: "", date: lastSyncDate)
                } else {
                    Text(Localizations.lastSync + " --")
                }
            }
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
