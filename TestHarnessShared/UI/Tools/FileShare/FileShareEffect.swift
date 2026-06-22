import Foundation

/// Effects that can be processed by a `FileShareProcessor`.
///
enum FileShareEffect: Equatable {
    /// The view appeared and should prepare the sample file for sharing.
    case viewAppeared
}
