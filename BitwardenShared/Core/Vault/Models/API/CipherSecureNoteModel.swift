/// API model for a cipher secure note.
///
struct CipherSecureNoteModel: Codable, Equatable {
    // MARK: Properties

    /// The type of secure note.
    let type: SecureNoteType?
}
