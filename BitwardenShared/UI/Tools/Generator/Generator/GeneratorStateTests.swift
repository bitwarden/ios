import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class GeneratorStateTests: XCTestCase {
    // MARK: Tests

    /// `formSections` returns the sections and fields for generating a passphrase.
    func test_formSections_passphrase() {
        var subject = GeneratorState()
        subject.passwordState.passwordGeneratorType = .passphrase

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate? Selection: Password Options: Password, Username
            Section: Options
              Menu: Password type Selection: Passphrase Options: Password, Passphrase
              Stepper: Number of words Value: 3 Range: 3...20
              Text: Word separator Value: -
              Toggle: Capitalize Value: false
              Toggle: Include number Value: false
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a password.
    func test_formSections_password() {
        var subject = GeneratorState()
        subject.passwordState.passwordGeneratorType = .password

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate? Selection: Password Options: Password, Username
            Section: Options
              Menu: Password type Selection: Password Options: Password, Passphrase
              Slider: Length Value: 14.0 Range: 5.0...128.0 Step: 1.0
              Toggle: A-Z Value: true
              Toggle: a-z Value: true
              Toggle: 0-9 Value: true
              Toggle: !@#$%^&* Value: false
              Stepper: Minimum numbers Value: 1 Range: 0...5
              Stepper: Minimum special Value: 1 Range: 0...5
              Toggle: Avoid ambiguous characters Value: false
            """
        }
    }

    // MARK: Private

    /// Returns a string containing a description of the vault list items.
    func dumpFormItems(_ fields: [GeneratorState.FormField<GeneratorState>], indent: String = "") -> String {
        fields.reduce(into: "") { result, field in
            result.append(indent)

            switch field.fieldType {
            case let .generatedValue(generatedValue):
                result.append("Generated: \(generatedValue.value.isEmpty ? "(empty)" : generatedValue.value)")
            case let .menuGeneratorType(menu):
                result.append(
                    "Menu: \(menu.title) Selection: \(menu.selection.localizedName) " +
                        "Options: \(menu.options.map(\.localizedName).joined(separator: ", "))"
                )
            case let .menuPasswordGeneratorType(menu):
                result.append(
                    "Menu: \(menu.title) Selection: \(menu.selection.localizedName) " +
                        "Options: \(menu.options.map(\.localizedName).joined(separator: ", "))"
                )
            case let .slider(slider):
                result.append(
                    "Slider: \(slider.title) Value: \(slider.value) " +
                        "Range: \(slider.range.description) Step: \(slider.step)"
                )
            case let .stepper(stepper):
                result.append("Stepper: \(stepper.title) Value: \(stepper.value) Range: \(stepper.range)")
            case let .text(text):
                result.append("Text: \(text.title) Value: \(text.value)")
            case let .toggle(toggle):
                result.append("Toggle: \(toggle.title) Value: \(toggle.isOn)")
            }

            if field != fields.last {
                result.append("\n")
            }
        }
    }

    /// Returns a string containing a description of the vault list sections.
    func dumpFormSections(_ sections: [GeneratorState.FormSection<GeneratorState>]) -> String {
        sections.reduce(into: "") { result, section in
            result.append("Section: \(section.title ?? "(empty)")\n")
            result.append(dumpFormItems(section.fields, indent: "  "))
            if section != sections.last {
                result.append("\n")
            }
        }
    }
}
