/// API model for a text send.
///
struct SendTextModel: Codable, Equatable {
    // MARK: Properties

    /// Whether the text is hidden by default.
    let hidden: Bool

    /// The text in the send.
    let text: String?
}
