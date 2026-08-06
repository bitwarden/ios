import Foundation

/// Actions that can be processed by a `FileShareProcessor`.
///
enum FileShareAction: Equatable {
    /// The text content field was updated.
    case textContentChanged(String)
}
