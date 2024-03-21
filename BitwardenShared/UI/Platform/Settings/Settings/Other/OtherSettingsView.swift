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

            clearClipboard

            connectToWatch

            giveFeedback
        }
        .scrollView()
        .navigationBar(title: Localizations.other, titleDisplayMode: .inline)
        .toast(store.binding(
            get: \.toast,
            send: OtherSettingsAction.toastShown
        ))
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
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
            .accessibilityIdentifier("SyncOnRefreshSwitch")

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
                selectionAccessibilityID: "ClearClipboardAfterLabel",
                selection: store.binding(
                    get: \.clearClipboardValue,
                    send: OtherSettingsAction.clearClipboardValueChanged
                )
            )
            .cornerRadius(10)
            .accessibilityIdentifier("ClearClipboardChooser")

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

    /// A link that redirects users to a feedback form.
    private var giveFeedback: some View {
        SettingsListItem(Localizations.giveFeedback, hasDivider: false) {
            store.send(.giveFeedbackPressed)
        } trailingContent: {
            Image(asset: Asset.Images.externalLink2)
                .resizable()
                .frame(width: 22, height: 22)
        }
        .cornerRadius(10)
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
