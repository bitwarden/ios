import BitwardenResources
import SwiftUI

// MARK: - DateFieldPicker

/// A reusable field for entering an optional calendar date.
///
/// The field renders as a collapsed row showing its title and, once set, the current value.
/// Tapping the row expands an inline graphical calendar; selecting a day populates the
/// value and collapses the calendar. When a date is set, a clear control is shown to reset it.
/// Because the field operates on an optional `Date?`, it can represent a genuinely empty value,
/// which the underlying `DatePicker` cannot do on its own.
///
public struct DateFieldPicker: View {
    // MARK: Properties

    /// The (optional) accessibility identifier applied to the field.
    let accessibilityIdentifier: String?

    /// A binding to the currently selected date, or `nil` if no date has been selected.
    @Binding var date: Date?

    /// The date the calendar opens to when the user expands an empty field.
    let defaultDate: Date

    /// The (optional) footer text shown below the field.
    let footer: String?

    /// The (optional) range of selectable dates.
    let range: ClosedRange<Date>?

    /// The identifier applied to the field, falling back to a generic default when the caller doesn't
    /// supply one. Child elements (the header button, the clear button) derive their own identifiers
    /// from this so multiple pickers on the same screen don't share child accessibility identifiers.
    private var resolvedAccessibilityIdentifier: String { accessibilityIdentifier ?? "DateFieldPicker" }

    /// The (optional) title of the field.
    let title: String?

    /// Whether the inline calendar is currently expanded.
    @State private var isExpanded = false

    /// Whether the view allows user interaction.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// Whether VoiceOver is currently running. The graphical calendar is difficult to navigate with
    /// VoiceOver, so a wheel picker is substituted when it is active.
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled: Bool

    /// Whether the wheel-style date picker should have accessibility focus. This is used to give the date
    /// picker immediate focus after expanding in VoiceOver mode.
    @AccessibilityFocusState private var isPickerFocused: Bool

    // MARK: View

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow()

            if isExpanded {
                Divider()
                datePicker()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
        .accessibilityIdentifier(resolvedAccessibilityIdentifier)
    }

    // MARK: Initialization

    /// Creates a new `DateFieldPicker`.
    ///
    /// - Parameters:
    ///   - title: The (optional) title of the field.
    ///   - accessibilityIdentifier: The (optional) accessibility identifier applied to the field.
    ///   - date: A binding to the selected date, or `nil` if no date has been selected.
    ///   - defaultDate: The date the calendar opens to when expanding an empty field. Defaults to
    ///     the current date.
    ///   - range: The (optional) range of selectable dates. When `nil` the calendar is unbounded.
    ///   - footer: The (optional) footer text shown below the field.
    ///
    public init(
        title: String? = nil,
        accessibilityIdentifier: String? = nil,
        date: Binding<Date?>,
        defaultDate: Date = Date().asUTCCalendarDay(),
        in range: ClosedRange<Date>? = nil,
        footer: String? = nil,
    ) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        _date = date
        self.defaultDate = defaultDate
        self.range = range
        self.footer = footer
    }

    /// Creates a new `DateFieldPicker` with the calendar already expanded. Used by tests to reach
    /// the live `DatePicker` node via `ViewInspector` without hosting the view to mutate `@State`
    /// and re-inspect.
    init(
        title: String? = nil,
        accessibilityIdentifier: String? = nil,
        date: Binding<Date?>,
        defaultDate: Date = Date().asUTCCalendarDay(),
        in range: ClosedRange<Date>? = nil,
        footer: String? = nil,
        isExpanded: Bool,
    ) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        _date = date
        self.defaultDate = defaultDate
        self.range = range
        self.footer = footer
        _isExpanded = State(initialValue: isExpanded)
    }

    // MARK: Private

    /// The inline `DatePicker`, optionally constrained to `range`. Uses the graphical calendar by
    /// default, falling back to the wheel style under VoiceOver where the calendar is hard to navigate.
    /// In the graphical style, selecting a day commits the value and collapses the calendar via
    /// `selection()`; the wheel style stays expanded so the user can scrub freely.
    ///
    /// `range`'s bounds are UTC-anchored, like `date`, so they're converted to the same local-day
    /// domain the picker operates in (see `selection()`) before being applied.
    @ViewBuilder
    private func datePicker() -> some View {
        let picker = Group {
            if let range {
                let localRange = range.lowerBound.asLocalCalendarDay() ... range.upperBound.asLocalCalendarDay()
                DatePicker("", selection: selection(), in: localRange, displayedComponents: [.date])
            } else {
                DatePicker("", selection: selection(), displayedComponents: [.date])
            }
        }
        .labelsHidden()
        .onChange(of: isExpanded) { newValue in
            isPickerFocused = newValue && voiceOverEnabled
        }
        .accessibilityFocused($isPickerFocused)

        if voiceOverEnabled {
            picker.datePickerStyle(.wheel)
        } else {
            picker.datePickerStyle(.graphical)
        }
    }

    /// The title and value (or placeholder) shown on the collapsed row.
    @ViewBuilder
    private func labelContent() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                Text(title)
                    .styleGuide(
                        .headline,
                        weight: .regular,
                        includeLinePadding: false,
                        includeLineSpacing: false,
                    )
                    .foregroundColor(
                        isEnabled
                            ? SharedAsset.Colors.textSecondary.swiftUIColor
                            : SharedAsset.Colors.textDisabled.swiftUIColor,
                    )
            }

            if let date {
                Text(date.longCalendarDateDisplay)
                    .styleGuide(.body)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// The collapsed row: the title and value (or placeholder), a clear control when a date is set,
    /// and a chevron. Tapping the title region or chevron toggles the inline calendar.
    @ViewBuilder
    private func headerRow() -> some View {
        HStack(spacing: 8) {
            Button {
                toggleExpanded()
            } label: {
                labelContent()
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(resolvedAccessibilityIdentifier)HeaderButton")
            .accessibilityHint(Localizations.selectDate)

            if date != nil {
                AccessoryButton(
                    asset: SharedAsset.Icons.circleX24,
                    accessibilityLabel: title.map { Localizations.clearFieldName($0) } ?? Localizations.clear,
                    accessibilityIdentifier: "\(resolvedAccessibilityIdentifier)ClearButton",
                ) {
                    clearDate()
                }
            }

            Button {
                toggleExpanded()
            } label: {
                SharedAsset.Icons.chevronDown24.swiftUIImage
                    .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
    }

    /// A binding driving the calendar: reads the selected date (falling back to `defaultDate` when
    /// empty) and, on selection, commits the value. With the graphical calendar, a selection also
    /// collapses the calendar; under VoiceOver the wheel stays expanded so continuous scrubbing does
    /// not dismiss it on the first change — the user collapses it via the header instead.
    ///
    /// `date` is UTC-anchored (see `iso8601DateOnlyString`), but the `DatePicker` reads/writes
    /// calendar days in the device's local time zone. The get/set here convert at that boundary so
    /// the day the user sees selected, and the day they pick, always match the day that gets stored.
    private func selection() -> Binding<Date> {
        Binding(
            get: { selectedLocalDay() },
            set: { newValue in commitSelectedLocalDay(newValue) },
        )
    }

    /// Commits a calendar day the user picked (in the `DatePicker`'s local-day domain) back into
    /// `date`, converting it to the UTC-anchored form used for storage, and collapses the calendar
    /// unless VoiceOver is active.
    private func commitSelectedLocalDay(_ localDay: Date) {
        date = localDay.asUTCCalendarDay()
        guard !voiceOverEnabled else { return }
        withAnimation { isExpanded = false }
    }

    /// The calendar day the `DatePicker` should currently show as selected: the stored date (or
    /// `defaultDate` when unset), converted from its UTC-anchored storage form into the local
    /// calendar day the `DatePicker` operates in.
    private func selectedLocalDay() -> Date {
        (date ?? defaultDate).asLocalCalendarDay()
    }

    /// Clears the selected date.
    private func clearDate() {
        withAnimation {
            date = nil
            isExpanded = false
        }
    }

    /// Toggles the inline calendar's expanded state.
    private func toggleExpanded() {
        withAnimation {
            isExpanded.toggle()
        }
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
    @Previewable @SwiftUI.State var date: Date? = Date(year: 2025, month: 4, day: 20)
    DateFieldPicker(title: "Date of birth", date: $date)
        .padding()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}

@available(iOS 17, *)
#Preview("With footer") {
    @Previewable @SwiftUI.State var date: Date? = Date(year: 2025, month: 4, day: 20)
    DateFieldPicker(
        title: "Expiration date",
        date: $date,
        footer: "The date this document expires.",
    )
    .padding()
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
