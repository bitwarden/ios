import BitwardenKit
import BitwardenShared

/// A factory to create `ErrorReporter` instances.
enum ErrorReporterFactory {
    // MARK: Static Functions

    /// Creates the default error reporter.
    static func makeDefaultErrorReporter() -> ErrorReporter {
        #if DEBUG
        OSLogErrorReporter()
        #else
        CrashlyticsErrorReporter.shared
        #endif
    }
}
