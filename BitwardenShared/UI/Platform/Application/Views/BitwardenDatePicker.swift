import SwiftUI

// MARK: - BitwardenDatePicker

/// A view that uses wraps a SwiftUI date picker in a custom label.
///
struct BitwardenDatePicker: View {
    // MARK: Private Properties

    /// The date picker's current size.
    @SwiftUI.State private var datePickerSize: CGSize = .zero

    /// The property used to track the non-nil selection state of the underlying date pickers.
    @SwiftUI.State private var nonNilSelection: Date

    // MARK: Properties

    /// The accessibility identifier for the date picker.
    var accessibilityIdentifier: String?

    /// The date value being displayed and selected.
    @Binding var selection: Date?

    /// The date components to display in this picker.
    var displayComponents: DatePicker.Components = .date

    // MARK: View

    var body: some View {
        ZStack(alignment: .center) {
            // A hidden date picker used to calculate the size for the scaled metrics of the actual
            // date picker below.
            DatePicker("", selection: $nonNilSelection, displayedComponents: displayComponents)
                .background(
                    GeometryReader { reader in
                        Color.clear.onAppear {
                            datePickerSize = reader.size
                        }
                    }
                )
                .labelsHidden()
                .allowsHitTesting(false)
                .fixedSize()
                .opacity(0)

            GeometryReader { reader in
                // The actual date picker used for user interaction, scaled to fit the same size as
                // the content displayed above it.
                DatePicker("", selection: $nonNilSelection, displayedComponents: displayComponents)
                    .scaleEffect(
                        x: reader.size.width / datePickerSize.width,
                        y: reader.size.height / datePickerSize.height,
                        anchor: .topLeading
                    )
                    .labelsHidden()
                    // Set an extremely low opacity here to hide this DatePicker from view while
                    // simultaniously allowing to still recieve touch events. This is the lowest
                    // opacity value that still allows user interaction.
                    .opacity(0.011)
                    .accessibilityIdentifier(accessibilityIdentifier ?? "")

                HStack {
                    Spacer()

                    if let selection {
                        switch displayComponents {
                        case .date:
                            Text(selection.formatted(date: .numeric, time: .omitted))
                        case .hourAndMinute:
                            Text(selection.formatted(date: .omitted, time: .shortened))
                        default:
                            Text(selection.formatted(date: .numeric, time: .shortened))
                        }
                    } else {
                        switch displayComponents {
                        case .date:
                            Text("mm/dd/yyyy")
                        case .hourAndMinute:
                            Text("--:-- --")
                        default:
                            Text("mm/dd/yyyy --:-- --")
                        }
                    }

                    Spacer()
                }
                .styleGuide(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Asset.Colors.fillTertiary.swiftUIColor)
                .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                .clipShape(Capsule())
                // Turn off hit testing here so that the DatePicker above receives all user interaction.
                .allowsHitTesting(false)
            }
        }
        .onChange(of: nonNilSelection, perform: { newValue in
            selection = newValue
        })
    }

    // MARK: Initialization

    /// Creates a `BitwardenDatePicker` with an optional date binding.
    ///
    /// - Parameters:
    ///   - selection: The binding for the optional date value to display within this component.
    ///   - displayComponents: The date components to display in this picker.
    ///   - accessibilityIdentifier: The accessibility identifier for the picker.
    ///   
    init(
        selection: Binding<Date?>,
        displayComponents: DatePicker.Components = .date,
        accessibilityIdentifier: String? = nil
    ) {
        _selection = selection
        let nonNilStartValue = selection.wrappedValue ?? Date()
        _nonNilSelection = .init(initialValue: nonNilStartValue)
        self.accessibilityIdentifier = accessibilityIdentifier
        self.displayComponents = displayComponents
        datePickerSize = .zero
    }

    /// Creates a `BitwardenDatePicker` with a date binding.
    ///
    /// - Parameters:
    ///   - selection: The binding for the date value to display within this component.
    ///   - displayComponents: The date components to display in this picker.
    ///   - accessibilityIdentifier: The accessibility identifier for the picker.
    ///
    init(
        selection: Binding<Date>,
        displayComponents: DatePicker.Components = .date,
        accessibilityIdentifier: String? = nil
    ) {
        _selection = Binding(
            get: {
                selection.wrappedValue
            }, set: { newValue in
                selection.wrappedValue = newValue ?? Date()
            }
        )
        let nonNilStartValue = selection.wrappedValue
        _nonNilSelection = .init(initialValue: nonNilStartValue)
        self.accessibilityIdentifier = accessibilityIdentifier
        self.displayComponents = displayComponents
        datePickerSize = .zero
    }
}
