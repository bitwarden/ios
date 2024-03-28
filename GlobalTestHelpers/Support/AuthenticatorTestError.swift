import Foundation

// MARK: AuthenticatorTestError

/// An example error type used in tests to properly test that methods properly `throws`
/// or `rethrows` errors.
///
/// These errors will typically be provided to a mocked type to be thrown at the
/// appropriate time. XCAssertThrows
public enum AuthenticatorTestError: LocalizedError {
    case example

    public var errorDescription: String? {
        switch self {
        case .example:
            return "An example error used to test throwing capabilities."
        }
    }
}
