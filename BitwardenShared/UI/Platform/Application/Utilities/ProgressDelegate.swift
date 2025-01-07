import Foundation

/// A protocol to report progress.
@MainActor
protocol ProgressDelegate: AnyObject {
    /// Reports progress in an operation.
    /// - Parameter progress: The progress being made in an operation.
    func report(progress: Double)
}
