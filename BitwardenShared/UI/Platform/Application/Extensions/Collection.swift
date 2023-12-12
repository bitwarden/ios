import Foundation

extension Collection {
    /// Returns the collection or `nil` if it is empty.
    var nilIfEmpty: Self? {
        isEmpty ? nil : self
    }
}
