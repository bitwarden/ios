import Foundation

/// Actions that can be processed by a `ManagePasskeysProcessor`.
///
/// This screen has no synchronous user interactions of its own; loading and deleting stored
/// credentials are handled as `ManagePasskeysEffect`s.
///
enum ManagePasskeysAction: Equatable {}
