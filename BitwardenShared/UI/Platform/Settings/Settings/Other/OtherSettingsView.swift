import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - OtherSettingsView

/// A view that allows users to configure miscellaneous settings.
///
struct OtherSettingsView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The current phase of the scene.
    @Environment(\.scenePhase) private var scenePhase

    /// The store used to render the view.
    @ObservedObject var store: Store<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            allowSyncOnRefresh

            syncNow

            VStack(alignment: .leading, spacing: 8) {
                clearClipboard

                allowUniversalClipboard

                if store.state.shouldShowConnectToWatchToggle {
                    connectToWatch
                }

                siriAndShortcutsAccess
            }

            notifications
        }
        .scrollView()
        .navigationBar(title: Localizations.other, titleDisplayMode: .inline)
        .toast(store.binding(
            get: \.toast,
            send: OtherSettingsAction.toastShown,
        ))
        .task {
            await store.perform(.streamLastSyncTime)
        }
        .task {
            await store.perform(.loadInitialValues)
        }
        .onChange(of: scenePhase) { newValue in
            guard newValue == .active else { return }
            Task { await store.perform(.refreshNotificationStatus) }
        }
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
    }

    // MARK: Private views

    /// The allow sync on refresh toggle and description.
    private var allowSyncOnRefresh: some View {
        BitwardenToggle(
            Localizations.enableSyncOnRefresh,
            isOn: store.binding(
                get: \.isAllowSyncOnRefreshToggleOn,
                send: OtherSettingsAction.toggleAllowSyncOnRefresh,
            ),
            accessibilityIdentifier: "SyncOnRefreshSwitch",
        ) {
            Text(Localizations.enableSyncOnRefreshDescription)
                .styleGuide(.footnote)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
        }
        .contentBlock()
    }

    /// The Universal Clipboard toggle button and its description.
    private var allowUniversalClipboard: some View {
        BitwardenToggle(
            Localizations.allowUniversalClipboard,
            isOn: store.binding(
                get: \.isAllowUniversalClipboardToggleOn,
                send: OtherSettingsAction.toggleAllowUniversalClipboard,
            ),
            accessibilityIdentifier: "UniversalClipboardChooser",
        ) {
            Text(Localizations.useUniversalClipboardToCopyDescriptionLong)
                .styleGuide(.footnote)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
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
                send: OtherSettingsAction.clearClipboardValueChanged,
            ),
        )
    }

    /// The connect to watch toggle.
    private var connectToWatch: some View {
        BitwardenToggle(
            Localizations.connectToWatch,
            isOn: store.binding(
                get: \.isConnectToWatchToggleOn,
                send: OtherSettingsAction.toggleConnectToWatch,
            ),
        )
        .contentBlock()
    }

    /// The notification status, a button to turn notifications on and the Agent Access warning.
    private var notifications: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Localizations.notifications)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                Spacer()

                Text(store.state.notificationAuthorization.allowsAlerts ? Localizations.on : Localizations.off)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier("NotificationsStatusLabel")
            }
            .padding(16)
            .accessibilityElement(children: .combine)
            .contentBlock()

            if !store.state.notificationAuthorization.allowsAlerts {
                AsyncButton(
                    store.state.notificationAuthorization == .notDetermined
                        ? Localizations.turnOnNow
                        : Localizations.openSettings,
                ) {
                    await store.perform(.turnOnNotifications)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("TurnOnNotificationsButton")
            }

            if store.state.showAgentAccessNotificationsWarning {
                Text(Localizations.agentAccessNotificationsOffWarning)
                    .styleGuide(.footnote)
                    .foregroundStyle(SharedAsset.Colors.error.swiftUIColor)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("AgentAccessNotificationsWarning")
            }
        }
    }

    /// Whether to allow access to Siri & Shortcuts using `AppIntent`s.
    private var siriAndShortcutsAccess: some View {
        BitwardenToggle(
            Localizations.siriAndShortcutsAccess,
            isOn: store.binding(
                get: \.isSiriAndShortcutsAccessToggleOn,
                send: OtherSettingsAction.toggleSiriAndShortcutsAccessToggleOn,
            ),
            accessibilityIdentifier: "SiriAndShortcutsAccessSwitch",
        ) {
            Text(Localizations.enableToAllowTheAppToRespondToSiriAndShortcutsUsingAppIntents)
                .styleGuide(.footnote)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
        }
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
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
            .multilineTextAlignment(.leading)
        }
    }
}

// MARK: Previews

#Preview {
    OtherSettingsView(store: Store(processor: StateProcessor(state: OtherSettingsState())))
}
