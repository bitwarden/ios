import BitwardenResources
import SwiftUI

// MARK: - SettingsPickerField

/// A field that displays a `CountdownDatePicker` when interacted with.
///
struct SettingsPickerField: View {
    // MARK: Properties

    /// The accessibility label used for the custom timeout value.
    let customTimeoutAccessibilityLabel: String

    /// The custom session timeout value.
    let customTimeoutValue: String

    /// Whether the menu field should have a bottom divider.
    let hasDivider: Bool

    /// The date picker value.
    @Binding var pickerValue: Int

    /// Whether or not to show the date picker.
    @SwiftUI.State var showTimePicker = false

    /// The title of the menu field.
    let title: String

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    showTimePicker.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                        .padding(.vertical, 19)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Text(customTimeoutValue)
                        .accessibilityLabel(customTimeoutAccessibilityLabel)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                }
                .styleGuide(.body)
                .id(title)
                .padding(.horizontal, 16)
            }

            if hasDivider {
                Divider()
                    .padding(.leading, 16)
            }

            if showTimePicker {
                CountdownDatePicker(duration: $pickerValue)
                    .frame(maxWidth: .infinity)

                if hasDivider {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `SettingsPickerField`.
    ///
    /// - Parameters:
    ///   - title: The title of the field.
    ///   - customTimeoutValue: The custom session timeout value.
    ///   - pickerValue: The date picker value.
    ///   - hasDivider: Whether or not the field has a bottom edge divider.
    ///   - customTimeoutAccessibilityLabel: The accessibility label used for the custom timeout value.
    ///
    init(
        title: String,
        customTimeoutValue: String,
        pickerValue: Binding<Int>,
        hasDivider: Bool = true,
        customTimeoutAccessibilityLabel: String
    ) {
        self.customTimeoutAccessibilityLabel = customTimeoutAccessibilityLabel
        self.customTimeoutValue = customTimeoutValue
        self.hasDivider = hasDivider
        _pickerValue = pickerValue
        self.title = title
    }
}

// MARK: Previews

#Preview {
    SettingsPickerField(
        title: "Custom",
        customTimeoutValue: "1:00",
        pickerValue: .constant(1),
        customTimeoutAccessibilityLabel: "one hour, zero minutes"
    )
}
