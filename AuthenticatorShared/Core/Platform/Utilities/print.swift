import Foundation

/// Wraps the `Swift.print()` within an `#if DEBUG` check, so that print statements have no effect in production
/// builds.
///
/// - Note: `print()` might cause
/// [security vulnerabilities](https://codifiedsecurity.com/mobile-app-security-testing-checklist-ios/).
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - separator: A string to print between each item. The default is a single space (" ").
///   - terminator: The string to print after all items have been printed. The default is a newline ("\n").
///
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(items, separator: separator, terminator: terminator)
    #endif
}
