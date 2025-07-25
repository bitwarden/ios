import BitwardenKit
import BitwardenResources
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
            .task { await store.perform(.loadData) }
            .toast(store.binding(
                get: \.toast,
                send: FlightRecorderLogsAction.toastShown
            ))
            .toolbar {
                closeToolbarItem {
                    store.send(.dismiss)
                }

                optionsToolbarItem {
                    Button(Localizations.shareAll) {
                        store.send(.shareAll)
                    }
                    .disabled(!store.state.isShareAllEnabled)

                    Button(Localizations.deleteAll, role: .destructive) {
                        store.send(.deleteAll)
                    }
                    .disabled(!store.state.isDeleteAllEnabled)
                }
            }
    }

    // MARK: Private Views

    /// The main content of the view, displaying either the list of logs or the empty content view.
    @ViewBuilder private var content: some View {
        if !store.state.logs.isEmpty {
            logsList
        } else {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.secureDevices.swiftUIImage,
                style: .mediumImage,
                message: Localizations.noLogsRecorded
            )
            .scrollView(centerContentVertically: true)
        }
    }

    /// A view containing the list of logs.
    private var logsList: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            ForEach(store.state.logs) { log in
                logRow(for: log)
            }
        }
        .scrollView()
    }

    /// A row view for a single log within the logs list.
    ///
    /// - Parameter log: The log to build the row view for.
    ///
    private func logRow(for log: FlightRecorderLogMetadata) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.formattedLoggingDateRange)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityLabel(log.loggingDateRangeAccessibilityLabel)

                HStack(spacing: 16) {
                    Text(log.fileSize)

                    if let formattedExpiration = log.formattedExpiration(currentDate: timeProvider.presentTime) {
                        Text(formattedExpiration)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .styleGuide(.subheadline)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(Localizations.share) {
                    store.send(.share(log))
                }

                Button(Localizations.delete, role: .destructive) {
                    store.send(.delete(log))
                }
                .disabled(log.isActiveLog)
            } label: {
                Asset.Images.ellipsisHorizontal24.swiftUIImage
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            }
            .accessibilityLabel(Localizations.more)
            .accessibilityIdentifier("FlightRecorderLogOptionsButton")
        }
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#if DEBUG
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
                        endDate: Date(year: 2025, month: 4, day: 1, hour: 8),
                        expirationDate: Date(year: 2025, month: 5, day: 1, hour: 8),
                        fileSize: "2 KB",
                        id: "1",
                        isActiveLog: true,
                        startDate: Date(year: 2025, month: 4, day: 1),
                        url: URL(string: "https://example.com")!
                    ),
                    FlightRecorderLogMetadata(
                        duration: .oneWeek,
                        endDate: Date(year: 2025, month: 3, day: 7),
                        expirationDate: Date(year: 2025, month: 4, day: 6),
                        fileSize: "12 KB",
                        id: "2",
                        isActiveLog: false,
                        startDate: Date(year: 2025, month: 3, day: 7),
                        url: URL(string: "https://example.com")!
                    ),
                    FlightRecorderLogMetadata(
                        duration: .oneHour,
                        endDate: Date(year: 2025, month: 3, day: 3, hour: 13),
                        expirationDate: Date(year: 2025, month: 4, day: 2, hour: 13),
                        fileSize: "1.5 MB",
                        id: "3",
                        isActiveLog: false,
                        startDate: Date(year: 2025, month: 3, day: 3, hour: 12),
                        url: URL(string: "https://example.com")!
                    ),
                    FlightRecorderLogMetadata(
                        duration: .twentyFourHours,
                        endDate: Date(year: 2025, month: 3, day: 2),
                        expirationDate: Date(year: 2025, month: 4, day: 1),
                        fileSize: "50 KB",
                        id: "4",
                        isActiveLog: false,
                        startDate: Date(year: 2025, month: 3, day: 1),
                        url: URL(string: "https://example.com")!
                    ),
                ]
            )
        )),
        timeProvider: PreviewTimeProvider(fixedDate: Date(year: 2025, month: 4, day: 1))
    )
    .navStackWrapped
}
#endif
