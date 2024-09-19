// MARK: - MasterPasswordGeneratorEffect

/// Effects handled by the `MasterPasswordGeneratorProcessor`.
///
enum MasterPasswordGeneratorEffect: Equatable {
    /// Any initial data for the view should be loaded.
    case loadData

    /// The generate button was tapped.
    case generate

    /// The save button was tapped.
    case save
}
