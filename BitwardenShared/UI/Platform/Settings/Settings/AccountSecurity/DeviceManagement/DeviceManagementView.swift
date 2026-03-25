import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - DeviceManagementView

/// A view that shows all the logged-in devices and allows the user to manage them.
///
struct DeviceManagementView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<DeviceManagementState, DeviceManagementAction, DeviceManagementEffect>

    // MARK: View

    var body: some View {
        LoadingView(state: store.state.loadingState) { devices in
            if devices.isEmpty {
                empty
                    .scrollView(centerContentVertically: true)
            } else {
                devicesList(devices)
                    .scrollView()
            }
        }
        .navigationBar(title: Localizations.manageDevices, titleDisplayMode: .inline)
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
            send: DeviceManagementAction.toastShown,
        ))
    }

    // MARK: Private Views

    /// The empty view.
    private var empty: some View {
        VStack(spacing: 20) {
            Image(decorative: Asset.Images.Illustrations.devices)
                .resizable()
                .frame(width: 100, height: 100)

            Text(Localizations.noDevicesFound)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    /// The list of devices.
    ///
    /// - Parameter devices: The devices to display.
    ///
    private func devicesList(_ devices: [DeviceListItem]) -> some View {
        VStack(spacing: 24) {
            ContentBlock(dividerLeadingPadding: 16) {
                ForEach(devices) { device in
                    DeviceRow(
                        device: device,
                        hasDivider: device != devices.last,
                        onTap: {
                            store.send(.deviceTapped(device))
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    DeviceManagementView(store: Store(processor: StateProcessor(state: DeviceManagementState(
        loadingState: .data([]),
    ))))
}

#Preview("Devices") {
    DeviceManagementView(store: Store(processor: StateProcessor(state: DeviceManagementState(
        loadingState: .data([
            DeviceListItem(
                id: "1",
                identifier: "abc123",
                displayName: "iPhone 15 Pro",
                deviceType: .iOS,
                isTrusted: true,
                isCurrentSession: true,
                hasPendingRequest: false,
                activityStatus: .today,
                firstLogin: Date(),
                lastActivityDate: Date(),
                pendingRequest: nil,
            ),
            DeviceListItem(
                id: "2",
                identifier: "def456",
                displayName: "Chrome Extension",
                deviceType: .chromeExtension,
                isTrusted: false,
                isCurrentSession: false,
                hasPendingRequest: true,
                activityStatus: .thisWeek,
                firstLogin: Date().addingTimeInterval(-86400 * 30),
                lastActivityDate: Date().addingTimeInterval(-86400 * 3),
                pendingRequest: nil,
            ),
            DeviceListItem(
                id: "3",
                identifier: "ghi789",
                displayName: "macOS",
                deviceType: .macOsDesktop,
                isTrusted: true,
                isCurrentSession: false,
                hasPendingRequest: false,
                activityStatus: .overThirtyDaysAgo,
                firstLogin: Date().addingTimeInterval(-86400 * 90),
                lastActivityDate: Date().addingTimeInterval(-86400 * 45),
                pendingRequest: nil,
            ),
        ]),
    ))))
}
#endif
