import SwiftUI

// MARK: - AboutView

/// A view that allows users to view miscellaneous information about the app.
///
struct AboutView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<AboutState, AboutAction, AboutEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            submitCrashLogs

            flightRecorderSection

            miscSection

            copyrightNotice
        }
        .scrollView(padding: 12)
        .navigationBar(title: Localizations.about, titleDisplayMode: .inline)
        .task {
            await store.perform(.loadData)
        }
        .task {
            await store.perform(.streamFlightRecorderEnabled)
        }
        .toast(store.binding(
            get: \.toast,
            send: AboutAction.toastShown
        ))
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .onChange(of: store.state.appReviewUrl) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearAppReviewURL)
        }
    }

    // MARK: Private views

    /// The copyright notice.
    private var copyrightNotice: some View {
        Text(store.state.copyrightText)
            .styleGuide(.caption2)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The section for the flight recorder.
    @ViewBuilder private var flightRecorderSection: some View {
        if store.state.isFlightRecorderFeatureFlagEnabled {
            ContentBlock(dividerLeadingPadding: 16) {
                BitwardenToggle(
                    Localizations.flightRecorder,
                    isOn: store.bindingAsync(
                        get: \.isFlightRecorderToggleOn,
                        perform: AboutEffect.toggleFlightRecorder
                    ),
                    accessibilityIdentifier: "FlightRecorderSwitch"
                )

                SettingsListItem(Localizations.viewRecordedLogs) {
                    store.send(.viewFlightRecorderLogsTapped)
                }
            }
        }
    }

    /// The section of miscellaneous about items.
    private var miscSection: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            externalLinkRow(Localizations.bitwardenHelpCenter, action: .helpCenterTapped)

            externalLinkRow(Localizations.privacyPolicy, action: .privacyPolicyTapped)

            externalLinkRow(Localizations.webVault, action: .webVaultTapped)

            externalLinkRow(Localizations.learnOrg, action: .learnAboutOrganizationsTapped)

            SettingsListItem(store.state.version) {
                store.send(.versionTapped)
            } trailingContent: {
                Asset.Images.copy24.swiftUIImage
                    .imageStyle(.rowIcon)
            }
        }
    }

    /// The submit crash logs toggle.
    private var submitCrashLogs: some View {
        ContentBlock {
            BitwardenToggle(
                Localizations.submitCrashLogs,
                isOn: store.binding(
                    get: \.isSubmitCrashLogsToggleOn,
                    send: AboutAction.toggleSubmitCrashLogs
                ),
                accessibilityIdentifier: "SubmitCrashLogsSwitch"
            )
        }
    }

    /// Returns a `SettingsListItem` configured for an external web link.
    ///
    /// - Parameters:
    ///   - name: The localized name of the row.
    ///   - action: An action to send when the row is tapped.
    /// - Returns: A `SettingsListItem` configured for an external web link.
    ///
    private func externalLinkRow(_ name: String, action: AboutAction) -> some View {
        SettingsListItem(name) {
            store.send(action)
        } trailingContent: {
            Asset.Images.externalLink24.swiftUIImage
                .imageStyle(.rowIcon)
        }
    }
}

// MARK: - Previews

#Preview {
    AboutView(store: Store(processor: StateProcessor(state: AboutState())))
}
