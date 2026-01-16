import BitwardenSdk

extension CipherView {
    // MARK: Properties

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    var isHidden: Bool {
        archivedDate != nil || deletedDate != nil
    }
}
