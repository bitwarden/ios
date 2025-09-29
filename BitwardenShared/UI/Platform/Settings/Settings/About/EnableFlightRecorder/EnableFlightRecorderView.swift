import BitwardenResources
import SwiftUI

// MARK: - EnableFlightRecorderView

/// A view that allows a user to enable and configure the flight recorder.
///
struct EnableFlightRecorderView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<EnableFlightRecorderState, EnableFlightRecorderAction, EnableFlightRecorderEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            header

            loggingDuration

            footer
        }
        .navigationBar(title: Localizations.enableFlightRecorder, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }

            saveToolbarItem {
                await store.perform(.save)
            }
        }
    }

    // MARK: Private Views

    /// The footer view.
    private var footer: some View {
        VStack(spacing: 12) {
            Text(Localizations.logsWillBeAutomaticallyDeletedAfter30DaysDescriptionLong)

            Text(LocalizedStringKey(
                Localizations.forDetailsOnWhatIsAndIsntLoggedVisitTheBitwardenHelpCenter(
                    ExternalLinksConstants.helpAndFeedback
                )
            ))
            .tint(SharedAsset.Colors.textInteraction.swiftUIColor)
        }
        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        .multilineTextAlignment(.center)
        .styleGuide(.footnote)
    }

    /// The header view.
    private var header: some View {
        VStack(spacing: 12) {
            Text(Localizations.experiencingAnIssue)
                .styleGuide(.title2, weight: .semibold)

            Group {
                Text(Localizations.enableTemporaryLoggingDescriptionLong)
                Text(Localizations.toGetStartedSetALoggingDurationDescriptionLong)
            }
            .styleGuide(.body)
        }
        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .padding(.top, 12)
    }

    /// The menu field for selecting the logging duration.
    private var loggingDuration: some View {
        BitwardenMenuField(
            title: Localizations.loggingDuration,
            accessibilityIdentifier: "LoggingDurationChooser",
            options: FlightRecorderLoggingDuration.allCases,
            selection: store.binding(
                get: \.loggingDuration,
                send: EnableFlightRecorderAction.loggingDurationChanged
            )
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    EnableFlightRecorderView(store: Store(processor: StateProcessor(state: EnableFlightRecorderState())))
        .navStackWrapped
}
#endif
