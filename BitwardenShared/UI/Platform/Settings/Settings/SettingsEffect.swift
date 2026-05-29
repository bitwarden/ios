/// Effects that can be processed by a `SettingsProcessor`.
///
enum SettingsEffect: Equatable {
    /// The view appeared so the initial data should be loaded.
    case appeared

    /// The plan row was tapped.
    case planPressed
}
