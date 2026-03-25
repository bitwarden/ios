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

    /// Whether to show a divider below the row.
    let hasDivider: Bool

    /// The action to perform when the device is tapped (for pending requests).
    let onTap: () -> Void

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Device name
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
                    }
                    .padding(.bottom, 4)

                    badgeRow

                    if device.lastActivityDate != nil {
                        recentlyActiveRow
                    }

                    firstLoginRow
                }

                if device.hasPendingRequest {
                    Spacer()

                    Image(asset: SharedAsset.Icons.chevronRight16)
                        .imageStyle(.accessoryIcon16)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)

            if hasDivider {
                Divider().padding(.leading, 16)
            }
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        .contentShape(Rectangle())
        .onTapGesture {
            if device.hasPendingRequest {
                onTap()
            }
        }
        .accessibilityIdentifier("DeviceRowCell")
    }

    // MARK: Private Views

    /// The badge row showing current session or pending request.
    @ViewBuilder
    private var badgeRow: some View {
        if device.isCurrentSession {
            statusIndicator(
                text: Localizations.currentSession,
                color: SharedAsset.Colors.badgeSuccessForeground.swiftUIColor
            )
        }

        if device.hasPendingRequest {
            statusIndicator(
                text: Localizations.pendingRequest,
                color: SharedAsset.Colors.badgeWarningForeground.swiftUIColor
            )
        }
    }

    /// The recently active row with bold label and regular date.
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

    /// Creates a status indicator with a colored dot and label.
    private func statusIndicator(text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(text)
                .styleGuide(.subheadline)
                .foregroundStyle(color)
        }
    }

    /// Formats a date for display with date and time.
    private func formattedDateTime(_ date: Date?) -> String {
        guard let date else { return Localizations.unknown }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Device Row - Current Session") {
    DeviceRow(
        device: DeviceListItem(
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
            pendingRequest: nil
        ),
        hasDivider: true,
        onTap: {}
    )
}

#Preview("Device Row - Pending Request") {
    DeviceRow(
        device: DeviceListItem(
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
            pendingRequest: nil
        ),
        hasDivider: false,
        onTap: {}
    )
}

#Preview("Device Row - Trusted Not Current") {
    DeviceRow(
        device: DeviceListItem(
            id: "3",
            identifier: "ghi789",
            displayName: "macOS Desktop",
            deviceType: .macOsDesktop,
            isTrusted: true,
            isCurrentSession: false,
            hasPendingRequest: false,
            activityStatus: .lastWeek,
            firstLogin: Date().addingTimeInterval(-86400 * 60),
            lastActivityDate: Date().addingTimeInterval(-86400 * 10),
            pendingRequest: nil
        ),
        hasDivider: true,
        onTap: {}
    )
}
#endif
