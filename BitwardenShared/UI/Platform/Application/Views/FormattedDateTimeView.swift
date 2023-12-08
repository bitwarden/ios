import SwiftUI

// MARK: - FormattedDateTimeView

/// A view that displays the date formatted with the date and time in the short style
/// (e.g. "11/30/2023 8:00 AM") along with an optional label.
///
struct FormattedDateTimeView: View {
    // MARK: Properties

    /// An optional label to display for the date.
    let label: String?

    /// The date to display formatted.
    let date: Date

    // MARK: View

    var body: some View {
        // Using `date.formatted(date: .numeric, time: .shortened)` leaves an undesired comma
        // between the date and time (e.g. "11/30/2023, 8:00 AM"). As a workaround, the formatted
        // date and time are concatenated together (e.g. "11/30/2023 8:00 AM").
        let formattedDate = date.formatted(date: .numeric, time: .omitted)
        let formattedTime = date.formatted(date: .omitted, time: .shortened)
        if let label {
            Text("\(label): \(formattedDate) \(formattedTime)")
        } else {
            Text("\(formattedDate) \(formattedTime)")
        }
    }

    // MARK: Initialization

    /// Initialize a `FormattedDateTimeView`.
    ///
    /// - Parameters:
    ///   - label: An optional label to display for the date.
    ///   - date: The date to display formatted.
    ///
    init(label: String? = nil, date: Date) {
        self.label = label
        self.date = date
    }
}

// MARK: Previews

#Preview {
    VStack(spacing: 16) {
        FormattedDateTimeView(label: Localizations.dateUpdated, date: Date())

        FormattedDateTimeView(date: Date())
    }
}
