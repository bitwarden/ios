import BitwardenResources
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
        LoadingView(state: store.state.loadingState) { pendingRequests in
            if pendingRequests.isEmpty {
                empty
                    .scrollView(centerContentVertically: true)
            } else {
                pendingRequestsList(pendingRequests)
                    .scrollView()
            }
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
        .refreshable { [weak store] in
            await store?.perform(.loadData)
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

                Image(decorative: Asset.Images.trash16)
                    .imageStyle(.accessoryIcon16(scaleWithFont: true))

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
            Image(decorative: Asset.Images.Illustrations.devices)
                .resizable()
                .frame(width: 100, height: 100)

            Text(Localizations.noPendingRequests)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    /// The list of pending requests.
    ///
    /// - Parameter pendingRequests: The pending login requests to display.
    ///
    private func pendingRequestsList(_ pendingRequests: [LoginRequest]) -> some View {
        VStack(spacing: 24) {
            ContentBlock(dividerLeadingPadding: 16) {
                ForEach(pendingRequests) { pendingRequest in
                    pendingRequestRow(pendingRequest, hasDivider: pendingRequest != pendingRequests.last)
                }
            }

            declineAllRequests
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
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("FingerprintValueLabel")

                    Text(pendingRequest.fingerprintPhrase ?? "")
                        .styleGuide(.caption2Monospaced)
                        .foregroundStyle(SharedAsset.Colors.textCodePink.swiftUIColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("FingerprintPhraseValue")

                    HStack {
                        Text(pendingRequest.requestDeviceType)
                            .styleGuide(.footnote)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .accessibilityIdentifier("DeviceTypeValueLabel")

                        Spacer()

                        Text(pendingRequest.creationDate.formatted(.dateTime))
                            .styleGuide(.footnote)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
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
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
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
