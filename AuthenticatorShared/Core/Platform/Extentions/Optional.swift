// MARK: - Optional

extension Optional where Wrapped: Collection {
    // MARK: Properties

    /// Returns true if the value is `nil` or an empty collection.
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}
