import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - LoginRequestView

/// A view that shows the information of the login request to allow the user to confirm or deny the request.
///
struct LoginRequestView: View {
    // MARK: Static Properties

    /// The formatter used to display the relative time of the login request.
    private static let relativeDateTimeFormatter = RelativeDateTimeFormatter()

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
                detailRow(
                    title: Localizations.fingerprintPhrase,
                    titleAccessibilityIdentifier: "FingerprintValueLabel",
                    value: store.state.request.fingerprintPhrase ?? "",
                    valueAccessibilityIdentifier: "FingerprintPhraseValue",
                    valueColor: SharedAsset.Colors.textCodePink.swiftUIColor,
                    valueStyle: .sensitiveInfoSmall,
                )

                detailRow(
                    title: Localizations.deviceType,
                    value: store.state.request.requestDeviceType,
                    valueAccessibilityIdentifier: "DeviceTypeValueLabel",
                )

                detailRow(
                    title: Localizations.ipAddress,
                    value: store.state.request.requestIpAddress,
                )

                detailRow(
                    title: Localizations.time,
                    value: Self.relativeDateTimeFormatter.localizedString(
                        for: store.state.request.creationDate,
                        relativeTo: Date(),
                    ),
                )
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

    /// The title text.
    private var titleText: some View {
        Text(Localizations.areYouTryingToLogIn)
            .styleGuide(.title2, weight: .semibold)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
    }

    // MARK: Private Methods

    /// Builds a titled row of details for display within the details `ContentBlock`.
    ///
    /// - Parameters:
    ///   - title: The title displayed above the value.
    ///   - titleAccessibilityIdentifier: The accessibility identifier applied to the title, if any.
    ///   - value: The value displayed below the title.
    ///   - valueAccessibilityIdentifier: The accessibility identifier applied to the value, if any.
    ///   - valueColor: The foreground color applied to the value.
    ///   - valueStyle: The style guide font applied to the value.
    ///
    private func detailRow(
        title: String,
        titleAccessibilityIdentifier: String? = nil,
        value: String,
        valueAccessibilityIdentifier: String? = nil,
        valueColor: Color = SharedAsset.Colors.textSecondary.swiftUIColor,
        valueStyle: StyleGuideFont = .body,
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .styleGuide(.headline, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .if(titleAccessibilityIdentifier != nil) { $0.accessibilityIdentifier(titleAccessibilityIdentifier!) }

            Text(value)
                .styleGuide(valueStyle)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.leading)
                .if(valueAccessibilityIdentifier != nil) { $0.accessibilityIdentifier(valueAccessibilityIdentifier!) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
