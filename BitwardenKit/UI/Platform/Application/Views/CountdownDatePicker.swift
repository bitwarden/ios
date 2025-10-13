import Foundation
import SwiftUI
import UIKit

// MARK: - CountdownDatePicker

/// A SwiftUI wrapped `UIDatePicker` that is configured to allow picking hour and minute values.
///
@MainActor
struct CountdownDatePicker: UIViewRepresentable {
    // MARK: Coordinator

    @MainActor
    class Coordinator: NSObject {
        // MARK: Properties

        /// The count down duration, in seconds.
        private let duration: Binding<Int>

        // MARK: Initialization

        /// Initializes a `CountdownDatePicker`.
        ///
        /// - Parameter duration: The count down duration.
        ///
        init(duration: Binding<Int>) {
            self.duration = duration
        }

        // MARK: Methods

        @objc
        func changed(_ sender: UIDatePicker) {
            duration.wrappedValue = Int(sender.countDownDuration)
        }
    }

    // MARK: UIViewRepresentable

    // MARK: Properties

    /// The count down duration, in seconds.
    @Binding var duration: Int

    // MARK: Methods

    func makeCoordinator() -> CountdownDatePicker.Coordinator {
        Coordinator(duration: $duration)
    }

    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .countDownTimer
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return datePicker
    }

    func updateUIView(_ datePicker: UIDatePicker, context: Context) {
        datePicker.countDownDuration = TimeInterval(duration)
    }
}
