// MARK: - Optional where Wrapped: Collection

extension Optional where Wrapped: Collection {
    // MARK: Properties

    /// Returns true if the value is `nil` or an empty collection.
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - Optional<String>

extension String? {
    // MARK: Properties

    /// Returns true if the value is `nil`, an empty string or a string full of `.whitespacesAndNewlines`.
    var isWhitespaceOrNil: Bool {
        guard let self else {
            return true
        }
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Methods

    /// Returns the `fallback` if the value is `nil` or whitespace. Otherwise, returns the same value.
    /// - Parameter fallback: The value to be used as a fallback when `nil` or whitespace.
    /// - Returns: `fallback` if the value is `nil` or whitespace. Otherwise, returns the same value.
    func fallbackOnWhitespaceOrNil(fallback: String?) -> String? {
        isWhitespaceOrNil ? fallback : self
    }

    /// Returns the `fallback` if the value is `nil` or whitespace. Otherwise, returns the same value.
    /// - Parameter fallback: The non-nil value to be used as a fallback when `nil` or whitespace.
    /// - Returns: `fallback` if the value is `nil` or whitespace. Otherwise, returns the same value.
    func fallbackOnWhitespaceOrNil(fallback: String) -> String {
        isWhitespaceOrNil ? fallback : self!
    }
}
