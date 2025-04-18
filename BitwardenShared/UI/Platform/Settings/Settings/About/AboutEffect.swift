// MARK: - AboutEffect

/// Effects that can be processed by the `AboutProcessor`.
///
enum AboutEffect: Equatable {
    /// The view appeared so the initial data should be loaded.
    case loadData

    /// Stream the enabled status of the flight recorder.
    case streamFlightRecorderEnabled

    /// The flight recorder toggle value changed.
    case toggleFlightRecorder(Bool)
}
