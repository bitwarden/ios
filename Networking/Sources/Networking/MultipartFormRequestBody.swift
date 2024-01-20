import Foundation

// MARK: - MultipartFormPart

/// Structure representing a single part from a multi-part form body.
///
public struct MultipartFormPart {
    // MARK: Properties

    /// Contents of the form part.
    public let data: Data

    /// Filename of the included data.
    public let fileName: String?

    /// Mime type of the included data. Defaults to "text/plain" if not defined.
    public let mimeType: String?

    /// Name of the form part.
    public let name: String
}

public extension MultipartFormPart {
    /// Creates a `MultipartFormPart` from file.
    ///
    /// - Parameters:
    ///    - data: Contents of the file.
    ///    - name: Name of the form part.
    ///    - fileName: File name for the data.
    ///    - mimeType: Optional mime type of the file.
    /// - Returns: A `MultipartFormPart` for the given file.
    ///
    static func file(
        data: Data,
        name: String,
        fileName: String,
        mimeType: String? = nil
    ) -> MultipartFormPart {
        MultipartFormPart(
            data: data,
            fileName: fileName,
            mimeType: mimeType ?? "application/octet-stream",
            name: name
        )
    }
}

// MARK: - MultipartFormRequestBody

/// A protocol for a `RequestBody` that can be encoded as an multipart form for the body of a
/// request.
///
public protocol MultipartFormRequestBody: RequestBody {
    /// Array of parts included in the form.
    var parts: [MultipartFormPart] { get }

    /// String used as a boundary between parts.
    var boundary: String { get }
}

public extension MultipartFormRequestBody {
    /// Additional headers to append to the request headers.
    var additionalHeaders: [String: String] {
        ["Content-Type": "multipart/form-data; charset=utf-8; boundary=\(boundary)"]
    }

    /// String used as a boundary between parts.
    var boundary: String {
        "--NETWORKING-BOUNDARY--"
    }

    /// The data representation of this request body.
    ///
    /// [W3 Documentation](https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.2)
    var data: Data {
        var data = Data()
        for part in parts {
            data.append("--\(boundary)\(crlf)")
            var contentDisposition = [
                "Content-Disposition: form-data",
                "name=\"\(part.name)\"",
            ]
            if let fileName = part.fileName {
                contentDisposition.append("filename=\"\(fileName)\"")
            }
            data.append(contentDisposition.joined(separator: "; ") + crlf)
            if let mimeType = part.mimeType {
                data.append("Content-Type: \(mimeType)\(crlf)")
            }
            data.append(crlf)
            data.append(part.data)
            data.append(crlf)
        }

        data.append("--\(boundary)--\(crlf)")
        return data
    }

    /// As with all MIME transmissions, "CR LF" (i.e., `%0D%0A`) is used to separate lines of data.
    var crlf: String { "\r\n" }

    /// Encodes the data to be included in the body of the request.
    ///
    /// - Returns: The encoded data to include in the body of the request.
    ///
    func encode() throws -> Data {
        data
    }
}

private extension Data {
    /// Appends a utf-8 encoded `String` to a `Data` object.
    ///
    /// - Parameter string: The `String` to append.
    ///
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
