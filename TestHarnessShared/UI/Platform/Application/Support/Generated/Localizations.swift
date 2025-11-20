// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Localizations {
  /// Create Passkey
  public static var createPasskey: String { return Localizations.tr("Localizable", "CreatePasskey", fallback: "Create Passkey") }
  /// Credentials
  public static var credentials: String { return Localizations.tr("Localizable", "Credentials", fallback: "Credentials") }
  /// Enter credentials above
  public static var enterCredentialsAbove: String { return Localizations.tr("Localizable", "EnterCredentialsAbove", fallback: "Enter credentials above") }
  /// Form Values
  public static var formValues: String { return Localizations.tr("Localizable", "FormValues", fallback: "Form Values") }
  /// Passkey Autofill
  public static var passkeyAutofill: String { return Localizations.tr("Localizable", "PasskeyAutofill", fallback: "Passkey Autofill") }
  /// Password
  public static var password: String { return Localizations.tr("Localizable", "Password", fallback: "Password") }
  /// Password: %@
  public static func passwordValue(_ p1: Any) -> String {
    return Localizations.tr("Localizable", "PasswordValue", String(describing: p1), fallback: "Password: %@")
  }
  /// Simple Login Form
  public static var simpleLoginForm: String { return Localizations.tr("Localizable", "SimpleLoginForm", fallback: "Simple Login Form") }
  /// Use this simple login form to test autofill functionality.
  public static var simpleLoginFormDescription: String { return Localizations.tr("Localizable", "SimpleLoginFormDescription", fallback: "Use this simple login form to test autofill functionality.") }
  /// Test Harness
  public static var testHarness: String { return Localizations.tr("Localizable", "TestHarness", fallback: "Test Harness") }
  /// Test Scenarios
  public static var testScenarios: String { return Localizations.tr("Localizable", "TestScenarios", fallback: "Test Scenarios") }
  /// Username
  public static var username: String { return Localizations.tr("Localizable", "Username", fallback: "Username") }
  /// Username: %@
  public static func usernameValue(_ p1: Any) -> String {
    return Localizations.tr("Localizable", "UsernameValue", String(describing: p1), fallback: "Username: %@")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Localizations {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = TestHarnessResources.localizationFunction(key:table:fallbackValue:)(key, table, value)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
