import BitwardenSdk

extension CipherView {
    // MARK: Properties

    /// Whether this cipher can be archived.
    var canBeArchived: Bool {
        archivedDate == nil && deletedDate == nil
    }

    /// Whether this cipher can be unarchived.
    var canBeUnarchived: Bool {
        archivedDate != nil && deletedDate == nil
    }

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    var isHidden: Bool {
        archivedDate != nil || deletedDate != nil
    }
}
