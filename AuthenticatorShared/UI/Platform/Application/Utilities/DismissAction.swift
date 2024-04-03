import Foundation

/// An action to perform on dismiss.
///
public struct DismissAction {
    /// A UUID for conformance to Equatable, Hashable.
    let id: UUID = .init()

    /// The action to perform on dismiss.
    var action: () -> Void
}

extension DismissAction: Equatable {
    public static func == (lhs: DismissAction, rhs: DismissAction) -> Bool {
        lhs.id == rhs.id
    }
}

extension DismissAction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
