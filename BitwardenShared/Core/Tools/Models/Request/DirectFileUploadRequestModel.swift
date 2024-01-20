import Foundation
import Networking

// MARK: - DirectFileUploadRequestModel

/// The request model for uploading a file directly.
///
struct DirectFileUploadRequestModel: MultipartFormRequestBody {
    // MARK: Properties

    var boundary: String { "--BWMobileFormBoundary\(date.timeIntervalSince1970 * 1000)" }

    /// The date to use in the ``boundry`` for this request.
    let date: Date

    let parts: [MultipartFormPart]

    // MARK: Initialization

    /// Creates a new `DirectFileUploadRequestModel`.
    ///
    /// - Parameters:
    ///   - data: The data of the file being uploaded.
    ///   - date: The date to use in the ``boundry`` for this request.
    ///   - fileName: The name of the file being uploaded.
    ///
    init(data: Data, date: Date = .now, fileName: String) {
        self.date = date
        parts = [
            .file(
                data: data,
                name: "data",
                fileName: fileName
            ),
        ]
    }
}
