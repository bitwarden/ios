import BitwardenResources
import SwiftUI

// MARK: - FlightRecorderSettingsSectionView

/// A reusable view component that displays Flight Recorder settings.
///
/// This view provides a toggle to enable/disable flight recording and displays the active log's
/// end date and time when logging is enabled. It also includes a button to view recorded logs
/// and a help link for more information about the Flight Recorder feature.
///
/// This component can be integrated into any settings view that needs to display Flight Recorder
/// settings.
///
public struct FlightRecorderSettingsSectionView: View {
    // MARK: Types

    public typealias FlightRecorderSettingsSectionStore = Store<
        FlightRecorderSettingsSectionState,
        FlightRecorderSettingsSectionAction,
        FlightRecorderSettingsSectionEffect,
    >

    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: FlightRecorderSettingsSectionStore

    // MARK: View

    public var body: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            BitwardenToggle(
                isOn: store.bindingAsync(
                    get: { $0.activeLog != nil },
                    perform: FlightRecorderSettingsSectionEffect.toggleFlightRecorder,
                ),
                accessibilityIdentifier: "FlightRecorderSwitch",
                accessibilityLabel: store.state.flightRecorderToggleAccessibilityLabel,
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(Localizations.flightRecorder)

                        Button {
                            openURL(ExternalLinksConstants.flightRecorderHelp)
                        } label: {
                            SharedAsset.Icons.questionCircle16.swiftUIImage
                                .scaledFrame(width: 16, height: 16)
                                .accessibilityLabel(Localizations.learnMore)
                        }
                        .buttonStyle(.fieldLabelIcon)
                    }

                    if let log = store.state.activeLog {
                        Text(Localizations.loggingEndsOnDateAtTime(log.formattedEndDate, log.formattedEndTime))
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .styleGuide(.subheadline)
                    }
                }
            }

            SettingsListItem(Localizations.viewRecordedLogs) {
                store.send(.viewLogsTapped)
            }
        }
    }

    // MARK: Initialization

    /// Creates a new `FlightRecorderSettingsSectionView`.
    ///
    /// - Parameter store: The `Store` for managing the Flight Recorder settings section state,
    ///     actions, and effects.
    ///
    public init(store: FlightRecorderSettingsSectionStore) {
        self.store = store
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Disabled") {
    FlightRecorderSettingsSectionView(
        store: Store(processor: StateProcessor(state: FlightRecorderSettingsSectionState())),
    )
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

#Preview("Enabled") {
    FlightRecorderSettingsSectionView(
        store: Store(processor: StateProcessor(state: FlightRecorderSettingsSectionState(
            activeLog: FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(timeIntervalSinceNow: 60 * 60 * -4),
            ),
        ))),
    )
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
