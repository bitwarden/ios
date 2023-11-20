import SwiftUI

// MARK: - ToggleView

/// A toggle with stylized text.
///
struct ToggleView: View {
    // MARK: Properties

    /// Whether or not the toggle is on.
    var isOn: Binding<Bool>

    /// The toggle's description.
    var description: String

    // MARK: View

    var body: some View {
        Toggle(isOn: isOn) {
            Text(description)
        }
        .toggleStyle(.bitwarden)
    }

    // MARK: Initialization

    /// Initializes a new `ToggleView`.
    ///
    /// - Parameters:
    ///   - isOn: Whether or not the toggle is on.
    ///   - description: The toggle's description.
    ///
    init(isOn: Binding<Bool>, description: String) {
        self.isOn = isOn
        self.description = description
    }
}

// MARK: Previews

#Preview {
    ToggleView(isOn: .constant(false), description: "Toggle description")
}
