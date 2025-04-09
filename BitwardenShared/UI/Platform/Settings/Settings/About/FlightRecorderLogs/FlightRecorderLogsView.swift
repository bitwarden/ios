import SwiftUI

// MARK: - FlightRecorderLogsView

/// A view that allows a user view the list of logs recorded by the flight recorder and share or
/// delete them.
///
struct FlightRecorderLogsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<FlightRecorderLogsState, FlightRecorderLogsAction, FlightRecorderLogsEffect>

    /// The `TimeProvider` used to calculate expiration dates.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.recordedLogs, titleDisplayMode: .inline)
            .toolbar {
                closeToolbarItem {
                    store.send(.dismiss)
                }
            }
    }

    // MARK: Private Views

    /// The main content of the view, displaying either the list of logs or the empty content view.
    @ViewBuilder private var content: some View {
        if !store.state.logs.isEmpty {
            logsList
        } else {
            EmptyContentView(
                image: Asset.Images.Illustrations.secureDevices.swiftUIImage,
                text: Localizations.noLogsRecorded,
                buttonContent: {
                    EmptyView()
                }
            )
        }
    }

    /// A view containing the list of logs.
    private var logsList: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            ForEach(store.state.logs) { log in
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.formattedLoggingDateRange)
                        .styleGuide(.body)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .accessibilityLabel(log.loggingDateRangeAccessibilityLabel)

                    HStack(spacing: 16) {
                        Text(log.fileSize)

                        Text(log.formattedExpiration(currentDate: timeProvider.presentTime))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                    .styleGuide(.subheadline)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                }
                .accessibilityElement(children: .combine)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .scrollView(padding: 12)
    }
}

// MARK: - Previews

#Preview("Empty") {
    FlightRecorderLogsView(
        store: Store(processor: StateProcessor(state: FlightRecorderLogsState())),
        timeProvider: PreviewTimeProvider()
    )
    .navStackWrapped
}

#Preview("Logs") {
    FlightRecorderLogsView(
        store: Store(processor: StateProcessor(
            state: FlightRecorderLogsState(
                logs: [
                    FlightRecorderLogMetadata(
                        duration: .eightHours,
                        fileSize: "12KB",
                        id: "1",
                        startDate: .now
                    ),
                    FlightRecorderLogMetadata(
                        duration: .eightHours,
                        fileSize: "12KB",
                        id: "2",
                        startDate: .now
                    ),
                    FlightRecorderLogMetadata(
                        duration: .eightHours,
                        fileSize: "12KB",
                        id: "3",
                        startDate: .now
                    ),
                ]
            )
        )),
        timeProvider: PreviewTimeProvider()
    )
    .navStackWrapped
}
