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
        .navigationBar(title: Localizations.devices, titleDisplayMode: .inline)
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
        IllustratedMessageView(
            image: Asset.Images.Illustrations.devices,
            message: Localizations.noDevicesFound,
        )
        .frame(maxWidth: .infinity)
    }

    /// The list of devices.
    ///
    /// - Parameter devices: The devices to display.
    ///
    private func devicesList(_ devices: [DeviceListItem]) -> some View {
        ContentBlock(dividerLeadingPadding: 16) {
            ForEach(devices) { device in
                DeviceRow(
                    store: store.child(
                        state: { _ in DeviceRowState(device: device) },
                        mapAction: DeviceManagementAction.deviceRow,
                        mapEffect: nil,
                    ),
                )
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
                activityStatus: .today,
                deviceType: .iOS,
                displayName: "iPhone 15 Pro",
                firstLogin: Date(),
                id: "1",
                identifier: "abc123",
                isCurrentSession: true,
                isTrusted: true,
                lastActivityDate: Date(),
                pendingRequest: nil,
            ),
            DeviceListItem(
                activityStatus: .pastSevenDays,
                deviceType: .chromeExtension,
                displayName: "Chrome Extension",
                firstLogin: Date().addingTimeInterval(-86400 * 30),
                id: "2",
                identifier: "def456",
                isCurrentSession: false,
                isTrusted: false,
                lastActivityDate: Date().addingTimeInterval(-86400 * 3),
                pendingRequest: nil,
            ),
            DeviceListItem(
                activityStatus: .overThirtyDaysAgo,
                deviceType: .macOsDesktop,
                displayName: "macOS",
                firstLogin: Date().addingTimeInterval(-86400 * 90),
                id: "3",
                identifier: "ghi789",
                isCurrentSession: false,
                isTrusted: true,
                lastActivityDate: Date().addingTimeInterval(-86400 * 45),
                pendingRequest: nil,
            ),
        ]),
    ))))
}
#endif
