import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - LoginRequestView

/// A view that shows the information of the login request to allow the user to confirm or deny the request.
///
struct LoginRequestView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginRequestState, LoginRequestAction, LoginRequestEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .center, spacing: 12) {
                titleText

                explanationText
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)

            ContentBlock(dividerLeadingPadding: 16) {
                fingerprintView

                deviceTypeView

                ipAddressView

                timeView
            }

            VStack(spacing: 12) {
                confirmButton

                denyButton
            }
        }
        .scrollView()
        .refreshable { [weak store] in
            await store?.perform(.reloadData)
        }
        .navigationBar(title: Localizations.logInRequested, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .task {
            await store.perform(.loadData)
        }
    }

    // MARK: Private Views

    /// The confirm login button.
    private var confirmButton: some View {
        AsyncButton(Localizations.confirmLogIn) {
            await store.perform(.answerRequest(approve: true))
        }
        .buttonStyle(.primary())
        .accessibilityIdentifier("ConfirmLoginButton")
    }

    /// The deny login button.
    private var denyButton: some View {
        AsyncButton(Localizations.denyLogIn) {
            await store.perform(.answerRequest(approve: false))
        }
        .buttonStyle(.secondary())
        .accessibilityIdentifier("DenyLoginButton")
    }

    /// The device type title and details.
    private var deviceTypeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.deviceType)
                .styleGuide(.headline, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(store.state.request.requestDeviceType)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("DeviceTypeValueLabel")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The explanation text.
    private var explanationText: some View {
        Text(
            Localizations.logInAttemptByXOnY(
                store.state.email ?? "",
                store.state.request.origin,
            ),
        )
        .styleGuide(.body)
        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        .accessibilityIdentifier("LogInAttemptByLabel")
    }

    /// The fingerprint phrase title and display.
    private var fingerprintView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.fingerprintPhrase)
                .styleGuide(.headline, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("FingerprintValueLabel")

            Text(store.state.request.fingerprintPhrase ?? "")
                .styleGuide(.sensitiveInfoSmall)
                .foregroundStyle(SharedAsset.Colors.textCodePink.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("FingerprintPhraseValue")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The IP address title and details.
    private var ipAddressView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.ipAddress)
                .styleGuide(.headline, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(store.state.request.requestIpAddress)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The time title and details.
    private var timeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.time)
                .styleGuide(.headline, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(RelativeDateTimeFormatter().localizedString(for: store.state.request.creationDate, relativeTo: Date()))
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The title text.
    private var titleText: some View {
        Text(Localizations.areYouTryingToLogIn)
            .styleGuide(.title2, weight: .semibold)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    LoginRequestView(store: Store(processor: StateProcessor(state: LoginRequestState(
        request: .fixture(
            creationDate: .now,
            fingerprintPhrase: "which-ninja-turtle-is-the-best",
        ),
    ))))
}
#endif
