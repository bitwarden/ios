// MARK: - AboutEffect

/// Effects that can be processed by the `AboutProcessor`.
///
enum AboutEffect: Equatable {
    /// Stream the active flight recorder log.
    case streamFlightRecorderLog

    /// The flight recorder toggle value changed.
    case toggleFlightRecorder(Bool)
}
