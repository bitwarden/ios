public protocol ConfigSettingsStore {
    /// Retrieves a feature flag value from the app's settings store.
    ///
    /// This method fetches the value for a specified feature flag from the app's settings store.
    /// The value is returned as a `Bool`. If the flag does not exist or cannot be decoded,
    /// the method returns `nil`.
    ///
    /// - Parameter name: The name of the feature flag to retrieve, represented as a `String`.
    /// - Returns: The value of the feature flag as a `Bool`, or `nil` if the flag does not exist
    ///     or cannot be decoded.
    ///
    func debugFeatureFlag(name: String) -> Bool?

    /// Sets a feature flag value in the app's settings store.
    ///
    /// This method updates or removes the value for a specified feature flag in the app's settings store.
    /// If the `value` parameter is `nil`, the feature flag is removed from the store. Otherwise, the flag
    /// is set to the provided boolean value.
    ///
    /// - Parameters:
    ///   - name: The name of the feature flag to set or remove, represented as a `String`.
    ///   - value: The boolean value to assign to the feature flag. If `nil`, the feature flag will be removed
    ///    from the settings store.
    ///
    func overrideDebugFeatureFlag(name: String, value: Bool?)
}
