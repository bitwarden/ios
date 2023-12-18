import SwiftUI

// MARK: - BitwardenDatePicker

/// A view that uses wraps a SwiftUI date picker in a custom label.
///
struct BitwardenDatePicker: View {
    // MARK: Properties

    /// The date value being displayed and selected.
    @Binding var selection: Date

    /// The date components to display in this picker.
    var displayComponents: DatePicker.Components = .date

    /// The date picker's current size.
    @SwiftUI.State private var datePickerSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .center) {
            // A hidden date picker used to calculate the size for the scaled metrics of the actual
            // date picker below.
            DatePicker("", selection: $selection, displayedComponents: displayComponents)
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
                DatePicker("", selection: $selection, displayedComponents: displayComponents)
                    .scaleEffect(
                        x: reader.size.width / datePickerSize.width,
                        y: reader.size.height / datePickerSize.height,
                        anchor: .topLeading
                    )
                    .labelsHidden()
                    .opacity(0.011)

                HStack {
                    Spacer()

                    switch displayComponents {
                    case .date:
                        Text(selection.formatted(date: .numeric, time: .omitted))
                    case .hourAndMinute:
                        Text(selection.formatted(date: .omitted, time: .shortened))
                    default:
                        Text(selection.formatted(date: .numeric, time: .shortened))
                    }

                    Spacer()
                }
                .styleGuide(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Asset.Colors.fillTertiary.swiftUIColor)
                .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                .clipShape(Capsule())
                .allowsHitTesting(false)
            }
        }
    }
}
