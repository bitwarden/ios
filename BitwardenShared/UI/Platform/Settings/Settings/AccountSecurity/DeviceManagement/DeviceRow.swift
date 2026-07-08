import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - DeviceRow

/// A row displaying device information in the device management list.
///
struct DeviceRow: View {
    // MARK: Properties

    /// The device to display.
    let device: DeviceListItem

    /// The action to perform when the device is tapped (for pending requests).
    let onTap: () -> Void

    // MARK: View

    var body: some View {
        Button {
            if device.hasPendingRequest {
                onTap()
            }
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    if device.isCurrentSession {
                        PillBadgeView(text: Localizations.currentSession, style: .success)
                    }

                    if device.hasPendingRequest {
                        PillBadgeView(text: Localizations.pendingRequest, style: .warning)
                    }

                    Text(device.displayName)
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                        .styleGuide(.bodySemibold)
                        .accessibilityIdentifier("DeviceNameLabel")

                    if device.isTrusted {
                        Text(Localizations.trusted)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .styleGuide(.subheadline)
                            .accessibilityIdentifier("TrustedLabel")
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if device.lastActivityDate != nil {
                            recentlyActiveRow
                        }

                        firstLoginRow
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if device.hasPendingRequest {
                    Image(asset: SharedAsset.Icons.chevronRight16)
                        .imageStyle(.accessoryIcon16)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(device.hasPendingRequest ? .isButton : [])
        .accessibilityIdentifier("DeviceRowCell")
    }

    // MARK: Private Views

    /// The recently active row with bold label and regular status.
    private var recentlyActiveRow: some View {
        HStack(spacing: 4) {
            Text(Localizations.recentlyActiveLabel)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .styleGuide(.subheadlineSemibold)

            Text(device.activityStatus.localizedString)
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

            Text(formattedDateTime(device.firstLogin))
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .styleGuide(.subheadline)
        }
        .accessibilityIdentifier("FirstLoginRow")
    }

    // MARK: Private Methods

    /// Formats a date for display with date and time.
    private func formattedDateTime(_ date: Date?) -> String {
        guard let date else { return Localizations.unknown }
        return DeviceRow.dateTimeFormatter.string(from: date)
    }
}

// MARK: - Private Static Helpers

private extension DeviceRow {
    /// Shared formatter for device activity dates.
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Previews

#if DEBUG
#Preview("Device Row - Current Session") {
    DeviceRow(
        device: DeviceListItem(
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
        ),
        onTap: {},
    )
    .contentBlock()
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

#Preview("Device Row - Pending Request") {
    DeviceRow(
        device: DeviceListItem(
            activityStatus: .thisWeek,
            deviceType: .chromeExtension,
            displayName: "Web vault - Chrome",
            firstLogin: Date().addingTimeInterval(-86400 * 30),
            id: "2",
            identifier: "def456",
            isCurrentSession: false,
            isTrusted: false,
            lastActivityDate: Date().addingTimeInterval(-86400 * 3),
            pendingRequest: nil,
        ),
        onTap: {},
    )
    .contentBlock()
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

#Preview("Device Row - Trusted Not Current") {
    DeviceRow(
        device: DeviceListItem(
            activityStatus: .lastWeek,
            deviceType: .macOsDesktop,
            displayName: "Desktop - macOS",
            firstLogin: Date().addingTimeInterval(-86400 * 60),
            id: "3",
            identifier: "ghi789",
            isCurrentSession: false,
            isTrusted: true,
            lastActivityDate: Date().addingTimeInterval(-86400 * 10),
            pendingRequest: nil,
        ),
        onTap: {},
    )
    .contentBlock()
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
