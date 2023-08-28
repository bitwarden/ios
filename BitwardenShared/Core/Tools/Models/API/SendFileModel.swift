/// API model for a file send.
///
struct SendFileModel: Codable, Equatable {
    // MARK: Properties

    /// The filename of the file to send.
    let fileName: String?

    /// The send file identifier.
    let id: String?

    /// The size of the file.
    let size: Int?

    ///
    let sizeName: String?
}
