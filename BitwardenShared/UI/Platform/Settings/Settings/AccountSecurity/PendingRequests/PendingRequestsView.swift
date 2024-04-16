import SwiftUI

// MARK: - PendingRequestsView

/// A view that shows all the pending login requests and allows the user to approve or deny them.
///
struct PendingRequestsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<PendingRequestsState, PendingRequestsAction, PendingRequestsEffect>

    // MARK: View

    var body: some View {
        GeometryReader { geometry in
            LoadingView(state: store.state.loadingState) { pendingRequests in
                if pendingRequests.isEmpty {
                    empty
                } else {
                    pendingRequestsList(pendingRequests)
                }
            }
            .padding(.vertical, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false)
        }
        .navigationBar(title: Localizations.pendingLogInRequests, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .task {
            await store.perform(.loadData)
        }
        .refreshable {
            await store.perform(.loadData)
        }
        .toast(store.binding(
            get: \.toast,
            send: PendingRequestsAction.toastShown
        ))
    }

    // MARK: Private Views

    /// The decline all requests button.
    private var declineAllRequests: some View {
        Button {
            store.send(.declineAllRequestsTapped)
        } label: {
            HStack(spacing: 4) {
                Spacer()

                Image(decorative: Asset.Images.trash)
                    .imageStyle(.accessoryIcon(scaleWithFont: true))

                Text(Localizations.declineAllRequests)

                Spacer()
            }
        }
        .buttonStyle(.secondary())
        .accessibilityIdentifier("DeclineAllRequestsButton")
        .accessibilityLabel(Localizations.declineAllRequests)
    }

    /// The empty view.
    private var empty: some View {
        VStack(spacing: 20) {
            Image(decorative: Asset.Images.pendingLoginRequestsEmpty)

            Text(Localizations.noPendingRequests)
                .styleGuide(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    /// The list of pending requests.
    ///
    /// - Parameter pendingRequests: The pending login requests to display.
    ///
    private func pendingRequestsList(_ pendingRequests: [LoginRequest]) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                ForEach(pendingRequests) { pendingRequest in
                    pendingRequestRow(pendingRequest, hasDivider: pendingRequest != pendingRequests.last)
                }
            }
            .cornerRadius(10)

            declineAllRequests

            Spacer()
        }
    }

    /// A pending request row.
    private func pendingRequestRow(_ pendingRequest: LoginRequest, hasDivider: Bool) -> some View {
        Button {
            store.send(.requestTapped(pendingRequest))
        } label: {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text(Localizations.fingerprintPhrase)
                        .styleGuide(.body)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("FingerprintValueLabel")

                    Text(pendingRequest.fingerprintPhrase ?? "")
                        .styleGuide(.caption2Monospaced)
                        .foregroundStyle(Asset.Colors.fingerprint.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("FingerprintPhraseValue")

                    HStack {
                        Text(pendingRequest.requestDeviceType)
                            .styleGuide(.footnote)
                            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                            .accessibilityIdentifier("DeviceTypeValueLabel")

                        Spacer()

                        Text(pendingRequest.creationDate.formatted(.dateTime))
                            .styleGuide(.footnote)
                            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .accessibilityElement(children: .combine)

                if hasDivider {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Asset.Colors.backgroundTertiary.swiftUIColor)
        .accessibilityIdentifier("LoginRequestCell")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    PendingRequestsView(store: Store(processor: StateProcessor(state: PendingRequestsState(
        loadingState: .data([])
    ))))
}

#Preview("Requests") {
    PendingRequestsView(store: Store(processor: StateProcessor(state: PendingRequestsState(
        loadingState: .data(
            [
                .fixture(
                    creationDate: .now,
                    fingerprintPhrase: "pineapple-on-pizza-is-the-best",
                    id: "1"
                ),
                .fixture(
                    creationDate: .now,
                    fingerprintPhrase: "coconuts-are-underrated",
                    id: "2"
                ),
            ]
        )
    ))))
}
#endif
