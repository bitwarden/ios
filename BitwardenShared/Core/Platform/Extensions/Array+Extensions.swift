extension Array {
    /// Gets the element on the index when inside the bounds
    /// of the array, otherwise returns `nil`.
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
