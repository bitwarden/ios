import Foundation
import SwiftUI
import UIKit

// MARK: - CountdownDatePicker

/// A SwiftUI wrapped `UIDatePicker` that is configured to allow picking hour and minute values.
///
struct CountdownDatePicker: UIViewRepresentable {
    // MARK: Coordinator

    class Coordinator: NSObject {
        // MARK: Properties

        /// The count down duration, in seconds.
        private let duration: Binding<TimeInterval>

        // MARK: Methods

        @objc
        func changed(_ sender: UIDatePicker) {
            duration.wrappedValue = sender.countDownDuration
        }

        // MARK: Initialization

        /// Initializes a `CountdownDatePicker`.
        ///
        /// - Parameter duration: The count down duration.
        ///
        init(duration: Binding<TimeInterval>) {
            self.duration = duration
        }
    }

    // MARK: UIViewRepresentable

    // MARK: Properties

    /// The count down durration.
    @Binding var duration: TimeInterval

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
        datePicker.countDownDuration = duration
    }
}
