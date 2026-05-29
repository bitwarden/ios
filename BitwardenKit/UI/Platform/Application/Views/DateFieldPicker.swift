import BitwardenResources
import SwiftUI

// MARK: - DateFieldPicker

/// A reusable field for entering an optional date and, optionally, time.
///
/// The field renders as a single collapsed row showing its title and current value (or a
/// placeholder when empty) with a chevron affordance. Tapping the row expands an inline native
/// `DatePicker` (graphical calendar) so a single tap reveals the picker. Because the field operates
/// on an optional `Date?`, it can represent a genuinely empty value — which the underlying
/// `DatePicker` cannot do on its own — and offers a control to clear a selected date.
///
public struct DateFieldPicker: View {
    // MARK: Properties

    /// The (optional) accessibility identifier applied to the field.
    let accessibilityIdentifier: String?

    /// A binding to the currently selected date, or `nil` if no date has been selected.
    @Binding var date: Date?

    /// The date used to seed the picker when the user first selects a date for an empty field.
    let defaultDate: Date

    /// The components shown by the underlying `DatePicker` (date, or date and time).
    let displayedComponents: DatePicker.Components

    /// The (optional) footer text shown below the field.
    let footer: String?

    /// The (optional) range of selectable dates.
    let range: ClosedRange<Date>?

    /// The (optional) title of the field.
    let title: String?

    /// Whether the inline date picker is currently expanded.
    @State private var isExpanded = false

    /// Whether the view allows user interaction.
    @Environment(\.isEnabled) var isEnabled: Bool

    // MARK: View

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerButton()

            if isExpanded {
                Divider()
                datePicker()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                if date != nil {
                    Divider()
                    clearButton()
                }
            }

            if let footer {
                Divider()
                Text(footer)
                    .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(
            isEnabled
                ? SharedAsset.Colors.backgroundSecondary.swiftUIColor
                : SharedAsset.Colors.backgroundSecondaryDisabled.swiftUIColor,
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier(accessibilityIdentifier ?? "DateFieldPicker")
    }

    // MARK: Initialization

    /// Creates a new `DateFieldPicker`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - accessibilityIdentifier: The (optional) accessibility identifier applied to the field.
    ///   - date: A binding to the selected date, or `nil` if no date has been selected.
    ///   - defaultDate: The date used to seed the picker when the user first selects a date for an
    ///     empty field. Defaults to the current date.
    ///   - displayedComponents: The components shown by the underlying `DatePicker`. Defaults to
    ///     `.date` for calendar-date-only selection.
    ///   - range: The (optional) range of selectable dates. When `nil` the picker is unbounded.
    ///   - footer: The (optional) footer text shown below the field.
    ///
    public init(
        title: String? = nil,
        accessibilityIdentifier: String? = nil,
        date: Binding<Date?>,
        defaultDate: Date = Date(),
        displayedComponents: DatePicker.Components = [.date],
        in range: ClosedRange<Date>? = nil,
        footer: String? = nil,
    ) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        _date = date
        self.defaultDate = defaultDate
        self.displayedComponents = displayedComponents
        self.range = range
        self.footer = footer
    }

    // MARK: Private

    /// A button to clear the selected date, shown in the expanded picker when a date is set.
    @ViewBuilder
    private func clearButton() -> some View {
        Button(Localizations.clear) {
            date = nil
            isExpanded = false
        }
        .buttonStyle(.bitwardenBorderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("DateFieldClearButton")
    }

    /// The inline native graphical `DatePicker`, optionally constrained to `range`.
    @ViewBuilder
    private func datePicker() -> some View {
        if let range {
            DatePicker("", selection: unwrappedDate(), in: range, displayedComponents: displayedComponents)
                .labelsHidden()
                .datePickerStyle(.graphical)
        } else {
            DatePicker("", selection: unwrappedDate(), displayedComponents: displayedComponents)
                .labelsHidden()
                .datePickerStyle(.graphical)
        }
    }

    /// The collapsed, tappable header row showing the title, value, and chevron.
    @ViewBuilder
    private func headerButton() -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if date != nil, let title {
                        Text(title)
                            .styleGuide(
                                .subheadline,
                                weight: .semibold,
                                includeLinePadding: false,
                                includeLineSpacing: false,
                            )
                            .foregroundColor(
                                isEnabled
                                    ? SharedAsset.Colors.textSecondary.swiftUIColor
                                    : SharedAsset.Colors.textDisabled.swiftUIColor,
                            )
                    }

                    Text(headerText())
                        .styleGuide(.body)
                        .foregroundColor(
                            date == nil
                                ? SharedAsset.Colors.textSecondary.swiftUIColor
                                : SharedAsset.Colors.textPrimary.swiftUIColor,
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SharedAsset.Icons.chevronDown24.swiftUIImage
                    .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("DateFieldHeaderButton")
    }

    /// The text shown on the collapsed row: the formatted date when set, otherwise the title (or a
    /// placeholder when there is no title).
    private func headerText() -> String {
        guard let date else { return title ?? Localizations.selectADate }
        return date.formatted(
            date: displayedComponents.contains(.date) ? .long : .omitted,
            time: displayedComponents.contains(.hourAndMinute) ? .shortened : .omitted,
        )
    }

    /// A binding that unwraps the optional `date`, falling back to `defaultDate` so it can drive the
    /// native `DatePicker`, which requires a non-optional `Date`.
    private func unwrappedDate() -> Binding<Date> {
        Binding(
            get: { date ?? defaultDate },
            set: { date = $0 },
        )
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview("Collapsed empty") {
    @Previewable @SwiftUI.State var date: Date?
    DateFieldPicker(title: "Date of birth", date: $date)
        .padding()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

@available(iOS 17, *)
#Preview("Collapsed selected") {
    @Previewable @SwiftUI.State var date: Date? = Date(year: 2023, month: 6, day: 23)
    DateFieldPicker(title: "Expiration date", date: $date)
        .padding()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

@available(iOS 17, *)
#Preview("Date and time") {
    @Previewable @SwiftUI.State var date: Date? = Date(year: 2023, month: 6, day: 23, hour: 8)
    DateFieldPicker(
        title: "Ends",
        date: $date,
        displayedComponents: [.date, .hourAndMinute],
        footer: "When this date passes the item will no longer be available.",
    )
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
