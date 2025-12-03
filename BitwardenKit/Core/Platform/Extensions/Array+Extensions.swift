// MARK: - Array + Extensions

public extension Array {
    /// Safely access elements in an array by index without running into an out-of-bounds error.
    /// This works like normal array subscript access, but if the index is out of bounds, then
    /// returns nil instead of throwing an error. This can be useful in cases, particularly in tests,
    /// where we want to access array elements by index number, and not have additional error handling
    /// if the index in question does not exist in the array.
    ///
    /// - Parameters:
    ///   - index: The position of the element to access.
    /// - Returns: The element at the specified index if it is within bounds, otherwise `nil`.
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
