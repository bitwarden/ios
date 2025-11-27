import BitwardenResources
import SwiftUI

// MARK: - SettingsPickerField

/// A field that displays a `CountdownDatePicker` when interacted with.
///
public struct SettingsPickerField: View {
    // MARK: Properties

    /// The accessibility label used for the custom timeout value.
    let customTimeoutAccessibilityLabel: String

    /// The custom session timeout value.
    let customTimeoutValue: String

    /// The footer text displayed below the toggle.
    let footer: String?

    /// The date picker value.
    @Binding var pickerValue: Int

    /// Whether or not to show the date picker.
    @SwiftUI.State var showTimePicker = false

    /// The title of the menu field.
    let title: String

    // MARK: View

    public var body: some View {
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

            if footer != nil {
                Divider()
                    .padding(.leading, 16)
            }

            if showTimePicker {
                CountdownDatePicker(duration: $pickerValue)
                    .frame(maxWidth: .infinity)

                if footer != nil {
                    Divider()
                        .padding(.leading, 16)
                }
            }

            if let footer {
                Text(footer)
                    .styleGuide(.subheadline)
                    .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `SettingsPickerField`.
    ///
    /// - Parameters:
    ///   - title: The title of the field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - customTimeoutValue: The custom session timeout value.
    ///   - pickerValue: The date picker value.
    ///   - customTimeoutAccessibilityLabel: The accessibility label used for the custom timeout value.
    ///
    public init(
        title: String,
        footer: String? = nil,
        customTimeoutValue: String,
        pickerValue: Binding<Int>,
        customTimeoutAccessibilityLabel: String
    ) {
        self.customTimeoutAccessibilityLabel = customTimeoutAccessibilityLabel
        self.customTimeoutValue = customTimeoutValue
        self.footer = footer
        _pickerValue = pickerValue
        self.title = title
    }
}

// MARK: Previews

#Preview {
    SettingsPickerField(
        title: "Custom",
        footer: nil,
        customTimeoutValue: "1:00",
        pickerValue: .constant(1),
        customTimeoutAccessibilityLabel: "one hour, zero minutes",
    )
}
