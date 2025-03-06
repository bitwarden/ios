import Foundation

// MARK: BitwardenTestError

/// An example error type used in tests to properly test that methods properly `throws`
/// or `rethrows` errors.
///
/// These errors will typically be provided to a mocked type to be thrown at the
/// appropriate time. XCAssertThrows
public enum BitwardenTestError: LocalizedError {
    case example

    public var errorDescription: String? {
        switch self {
        case .example:
            return "An example error used to test throwing capabilities."
        }
    }
}
