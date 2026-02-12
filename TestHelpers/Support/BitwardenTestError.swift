import Foundation

// MARK: BitwardenTestError

/// An example error type used in tests to properly test that methods properly `throws`
/// or `rethrows` errors.
///
/// These errors will typically be provided to a mocked type to be thrown at the
/// appropriate time. XCAssertThrows
public enum BitwardenTestError: Equatable, LocalizedError {
    case example
    case mock(String)

    public var errorDescription: String? {
        switch self {
        case .example:
            "An example error used to test throwing capabilities."
        case let .mock(string):
            "A mock error with the string: \(string)."
        }
    }
}
