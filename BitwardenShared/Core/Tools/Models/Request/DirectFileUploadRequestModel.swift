import Foundation
import Networking

// MARK: - DirectFileUploadRequestModel

/// The request model for uploading a file directly.
///
struct DirectFileUploadRequestModel: MultipartFormRequestBody {
    // MARK: Properties

    /// String used as a boundary between parts.
    var boundary: String { "--BWMobileFormBoundary\(date.timeIntervalSince1970 * 1000)" }

    /// The date to use in the `boundary` for this request.
    let date: Date

    /// Array of parts included in the form.
    let parts: [MultipartFormPart]

    // MARK: Initialization

    /// Creates a new `DirectFileUploadRequestModel`.
    ///
    /// - Parameters:
    ///   - additionalParts: Additional parts to include with the uploaded file.
    ///   - data: The data of the file being uploaded.
    ///   - date: The date to use in the `boundary` for this request.
    ///   - fileName: The name of the file being uploaded.
    ///
    init(
        additionalParts: [MultipartFormPart]? = nil,
        data: Data,
        date: Date = .now,
        fileName: String
    ) {
        self.date = date
        parts = [
            .file(
                data: data,
                name: "data",
                fileName: fileName
            ),
        ] + (additionalParts ?? [])
    }
}
