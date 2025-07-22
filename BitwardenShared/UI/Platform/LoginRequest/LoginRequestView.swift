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
            titleText

            explanationText

            fingerprintView

            deviceTypeView

            ipAddressView

            timeView

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
                .styleGuide(.body, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(store.state.request.requestDeviceType)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("DeviceTypeValueLabel")
        }
    }

    /// The explanation text.
    private var explanationText: some View {
        Text(
            Localizations.logInAttemptByXOnY(
                store.state.email ?? "",
                store.state.request.origin
            )
        )
        .styleGuide(.body)
        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.leading)
        .accessibilityIdentifier("LogInAttemptByLabel")
    }

    /// The fingerprint phrase title and display.
    private var fingerprintView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localizations.fingerprintPhrase)
                .styleGuide(.body, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("FingerprintValueLabel")

            Text(store.state.request.fingerprintPhrase ?? "")
                .styleGuide(.bodyMonospaced)
                .foregroundStyle(SharedAsset.Colors.textCodePink.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("FingerprintPhraseValue")
        }
    }

    /// The IP address title and details.
    private var ipAddressView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.ipAddress)
                .styleGuide(.body, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(store.state.request.requestIpAddress)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.leading)
        }
    }

    /// The time title and details.
    private var timeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.time)
                .styleGuide(.body, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(RelativeDateTimeFormatter().localizedString(for: store.state.request.creationDate, relativeTo: Date()))
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.leading)
        }
    }

    /// The title text.
    private var titleText: some View {
        Text(Localizations.areYouTryingToLogIn)
            .styleGuide(.title, weight: .bold)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    LoginRequestView(store: Store(processor: StateProcessor(state: LoginRequestState(
        request: .fixture(
            creationDate: .now,
            fingerprintPhrase: "which-ninja-turtle-is-the-best"
        )
    ))))
}
#endif
