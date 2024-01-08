// swiftlint:disable:this file_name

extension [VaultListItem] {
    /// Group the array into a dictionary sorted by id.
    ///
    /// - Returns: A dictionary of the array elements sorted by id.
    ///
    func byId() -> [String: VaultListItem] {
        var result = [String: VaultListItem]()
        forEach { result[$0.id] = $0 }
        return result
    }

    /// Update the array with a batch of possible updates.
    ///
    /// - Parameters:
    ///   - updatedValues: An array of updates to make the items are found in the current array.
    ///   - includeNewValues: A flag for including new values not found in the current array. Default is `false`.
    /// - Returns: An updated version of the array including the new elements.
    ///
    func updated(
        with updatedValues: [VaultListItem],
        includeNewValues: Bool = false
    ) -> [VaultListItem] {
        var result = byId()
        updatedValues.forEach { new in
            if includeNewValues || result.keys.contains(new.id) {
                result[new.id] = new
            }
        }
        return result.values
            .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    }
}
