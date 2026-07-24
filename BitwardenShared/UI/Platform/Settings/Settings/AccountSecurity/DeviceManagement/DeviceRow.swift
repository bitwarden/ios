import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - DeviceRowState

/// An object representing the visual state of a `DeviceRow`.
struct DeviceRowState: Equatable {
    // MARK: Properties

    /// The device to display.
    let device: DeviceListItem

    /// The formatted first-login date and time for display.
    var formattedFirstLogin: String {
        DeviceRowState.dateTimeFormatter.string(from: device.firstLogin)
    }
}

extension DeviceRowState {
    /// Shared formatter for device activity dates.
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - DeviceRowAction

/// Actions that can be sent from a `DeviceRow`.
enum DeviceRowAction: Equatable, Sendable {
    /// The row was tapped (for devices with a pending request).
    case rowTapped(DeviceListItem)
}

// MARK: - DeviceRow

/// A row displaying device information in the device management list.
///
struct DeviceRow: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<DeviceRowState, DeviceRowAction, Void>

    // MARK: View

    var body: some View {
        if store.state.device.hasPendingRequest {
            Button {
                store.send(.rowTapped(store.state.device))
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("DeviceRowCell")
        } else {
            rowContent
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("DeviceRowCell")
        }
    }

    // MARK: Private Views

    /// The row content shared between actionable and non-actionable states.
    @ViewBuilder private var rowContent: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                if store.state.device.isCurrentSession {
                    PillBadgeView(text: Localizations.currentSession, style: .info)
                        .padding(.bottom, 14)
                } else if store.state.device.hasPendingRequest {
                    PillBadgeView(text: Localizations.pendingRequest, style: .warning)
                        .padding(.bottom, 14)
                }

                Text(store.state.device.displayName)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.bodySemibold)
                    .accessibilityIdentifier("DeviceNameLabel")

                if store.state.device.isTrusted {
                    Text(Localizations.trusted)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .styleGuide(.subheadline)
                        .padding(.top, 2)
                        .accessibilityIdentifier("TrustedLabel")
                }

                VStack(alignment: .leading, spacing: 0) {
                    if store.state.device.lastActivityDate != nil {
                        recentlyActiveRow
                    }

                    firstLoginRow
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if store.state.device.hasPendingRequest {
                Image(asset: SharedAsset.Icons.chevronRight16)
                    .imageStyle(.accessoryIcon16)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    /// The recently active row with bold label and regular status.
    private var recentlyActiveRow: some View {
        HStack(spacing: 4) {
            Text(Localizations.recentlyActiveLabel)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .styleGuide(.subheadlineSemibold)

            Text(store.state.device.activityStatus.localizedString)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .styleGuide(.subheadline)
        }
        .accessibilityIdentifier("RecentlyActiveRow")
    }

    /// The first login row with bold label and regular date.
    private var firstLoginRow: some View {
        HStack(spacing: 4) {
            Text(Localizations.firstLoginLabel)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .styleGuide(.subheadlineSemibold)

            Text(store.state.formattedFirstLogin)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .styleGuide(.subheadline)
        }
        .accessibilityIdentifier("FirstLoginRow")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Device Row - Current Session") {
    DeviceRow(
        store: Store(processor: StateProcessor(state: DeviceRowState(device: DeviceListItem(
            activityStatus: .today,
            deviceType: .iOS,
            displayName: "Mobile - iOS",
            firstLogin: Date(),
            id: "1",
            identifier: "abc123",
            isCurrentSession: true,
            isTrusted: true,
            lastActivityDate: Date(),
            pendingRequest: nil,
        )))),
    )
    .contentBlock()
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

#Preview("Device Row - Pending Request") {
    DeviceRow(
        store: Store(processor: StateProcessor(state: DeviceRowState(device: DeviceListItem(
            activityStatus: .pastSevenDays,
            deviceType: .chromeExtension,
            displayName: "Web vault - Chrome",
            firstLogin: Date().addingTimeInterval(-86400 * 30),
            id: "2",
            identifier: "def456",
            isCurrentSession: false,
            isTrusted: false,
            lastActivityDate: Date().addingTimeInterval(-86400 * 3),
            pendingRequest: .fixture(),
        )))),
    )
    .contentBlock()
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

#Preview("Device Row - Trusted Not Current") {
    DeviceRow(
        store: Store(processor: StateProcessor(state: DeviceRowState(device: DeviceListItem(
            activityStatus: .pastFourteenDays,
            deviceType: .macOsDesktop,
            displayName: "Desktop - macOS",
            firstLogin: Date().addingTimeInterval(-86400 * 60),
            id: "3",
            identifier: "ghi789",
            isCurrentSession: false,
            isTrusted: true,
            lastActivityDate: Date().addingTimeInterval(-86400 * 10),
            pendingRequest: nil,
        )))),
    )
    .contentBlock()
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
