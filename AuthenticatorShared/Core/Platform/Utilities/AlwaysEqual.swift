import Foundation

@propertyWrapper
struct AlwaysEqual<Value>: Equatable {
    var wrappedValue: Value
    static func == (lhs: AlwaysEqual<Value>, rhs: AlwaysEqual<Value>) -> Bool {
        true
    }
}
