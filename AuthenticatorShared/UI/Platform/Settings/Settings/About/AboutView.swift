import SwiftUI

// MARK: - AboutView

/// A view that allows users to view miscellaneous information about the app.
///
struct AboutView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<AboutState, AboutAction, Void>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            submitCrashLogs

            miscSection

            copyrightNotice
        }
        .scrollView()
        .navigationBar(title: Localizations.about, titleDisplayMode: .inline)
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
        .onChange(of: store.state.giveFeedbackUrl) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearGiveFeedbackURL)
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

    /// The section of miscellaneous about items.
    private var miscSection: some View {
        VStack(spacing: 0) {
            externalLinkRow(Localizations.bitwardenHelpCenter, action: .helpCenterTapped)

            externalLinkRow(Localizations.privacyPolicy, action: .privacyPolicyTapped)

            externalLinkRow(Localizations.webVault, action: .webVaultTapped)

            externalLinkRow(Localizations.learnOrg, action: .learnAboutOrganizationsTapped)

            externalLinkRow(Localizations.giveFeedback, action: .giveFeedbackTapped)

            SettingsListItem(store.state.version, hasDivider: false) {
                store.send(.versionTapped)
            } trailingContent: {
                Asset.Images.copy.swiftUIImage
                    .imageStyle(.rowIcon)
            }
        }
        .cornerRadius(10)
    }

    /// The submit crash logs toggle.
    private var submitCrashLogs: some View {
        Toggle(isOn: store.binding(
            get: \.isSubmitCrashLogsToggleOn,
            send: AboutAction.toggleSubmitCrashLogs
        )) {
            Text(Localizations.submitCrashLogs)
        }
        .toggleStyle(.bitwarden)
        .styleGuide(.body)
        .accessibilityIdentifier("SubmitCrashLogsSwitch")
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
            Asset.Images.externalLink2.swiftUIImage
                .imageStyle(.rowIcon)
        }
    }
}

// MARK: - Previews

#Preview {
    AboutView(store: Store(processor: StateProcessor(state: AboutState())))
}
