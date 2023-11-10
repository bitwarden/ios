/// Effects that can be processed by a `GeneratorHistoryProcessor`.
///
enum GeneratorHistoryEffect {
    /// The generator history appeared on screen.
    case appeared

    /// The clear button was tapped to clear the list of passwords.
    case clearList
}
