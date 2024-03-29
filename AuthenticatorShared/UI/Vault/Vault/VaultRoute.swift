import BitwardenSdk
import Foundation

// MARK: - VaultRoute

/// A route to a specific screen in the vault tab.
public enum VaultRoute: Equatable, Hashable {
    case onboarding
}

@propertyWrapper
struct AlwaysEqual<Value>: Equatable {
    var wrappedValue: Value
    static func == (lhs: AlwaysEqual<Value>, rhs: AlwaysEqual<Value>) -> Bool {
        true
    }
}
