/// An enum describing the type of data in a send.
///
enum SendType: Int, Codable {
    /// The send contains text data.
    case text = 0

    /// The send contains an attached file.
    case file = 1
}
