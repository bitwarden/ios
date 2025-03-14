import AVFoundation

// MARK: - ScanCodeState

/// State to define the status of scanning a QR code.
///
struct ScanCodeState: Equatable {
    /// Whether or not to show an option for manual entry
    var showManualEntry: Bool
}
