import BitwardenResources
import SwiftUI

public extension View {
    /// Displays a toast banner indicating that the flight recorder is active.
    ///
    /// - Parameters:
    ///   - activeLog: The active flight recorder log metadata used to display the end date/time.
    ///   - additionalBottomPadding: Additional bottom padding to apply to the toast banner.
    ///   - isVisible: A binding to control the visibility of the toast banner.
    ///   - goToSettingsAction: The action to perform when the "Go to Settings" button is tapped.
    ///
    /// - Returns: A view with the flight recorder toast banner applied.
    ///
    func flightRecorderToastBanner(
        activeLog: FlightRecorderData.LogMetadata?,
        additionalBottomPadding: CGFloat = 0,
        isVisible: Binding<Bool>,
        goToSettingsAction: @escaping () -> Void,
    ) -> some View {
        toastBanner(
            title: Localizations.flightRecorderOn,
            subtitle: {
                guard let activeLog else { return "" }
                return Localizations.flightRecorderWillBeActiveUntilDescriptionLong(
                    activeLog.formattedEndDate,
                    activeLog.formattedEndTime,
                )
            }(),
            additionalBottomPadding: additionalBottomPadding,
            isVisible: isVisible,
        ) {
            Button(Localizations.goToSettings) {
                goToSettingsAction()
            }
        }
    }
}
