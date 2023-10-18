import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class GeneratorStateTests: XCTestCase {
    // MARK: Tests

    /// `formSections` returns the sections and fields for generating a password.
    func test_formSections_password() {
        let subject = GeneratorState()

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Picker: What would you like to generate? Value: Password
            Section: Options
              Picker: Password type Value: Password
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

    /// `generatorTypeValue` can be used to get the raw value of `generatorType`.
    func test_generatorTypeValue_getter() {
        var subject = GeneratorState()

        subject.generatorType = .password
        XCTAssertEqual(subject.generatorTypeValue, Localizations.password)

        subject.generatorType = .username
        XCTAssertEqual(subject.generatorTypeValue, Localizations.username)
    }

    /// `generatorTypeValue` can be used to set the raw value of `generatorType`.
    func test_generatorTypeValue_setter() {
        var subject = GeneratorState()

        subject.generatorTypeValue = Localizations.password
        XCTAssertEqual(subject.generatorType, .password)

        subject.generatorTypeValue = Localizations.username
        XCTAssertEqual(subject.generatorType, .username)
    }

    /// `passwordGeneratorTypeValue` can be used to set the raw value of `passwordGeneratorType`.
    func test_passwordState_passwordGeneratorType_getter() {
        var subject = GeneratorState()

        subject.passwordState.passwordGeneratorType = .passphrase
        XCTAssertEqual(subject.passwordState.passwordGeneratorTypeValue, Localizations.passphrase)

        subject.passwordState.passwordGeneratorType = .password
        XCTAssertEqual(subject.passwordState.passwordGeneratorTypeValue, Localizations.password)
    }

    /// `passwordGeneratorTypeValue` can be used to set the raw value of `passwordGeneratorType`.
    func test_passwordState_passwordGeneratorType_setter() {
        var subject = GeneratorState()

        subject.passwordState.passwordGeneratorTypeValue = Localizations.passphrase
        XCTAssertEqual(subject.passwordState.passwordGeneratorType, .passphrase)

        subject.passwordState.passwordGeneratorTypeValue = Localizations.password
        XCTAssertEqual(subject.passwordState.passwordGeneratorType, .password)
    }

    // MARK: Private

    /// Returns a string containing a description of the vault list items.
    func dumpFormItems(_ fields: [GeneratorState.FormField<GeneratorState>], indent: String = "") -> String {
        fields.reduce(into: "") { result, field in
            result.append(indent)

            switch field.fieldType {
            case let .generatedValue(generatedValue):
                result.append("Generated: \(generatedValue.value.isEmpty ? "(empty)" : generatedValue.value)")
            case let .picker(picker):
                result.append("Picker: \(picker.title) Value: \(picker.value)")
            case let .slider(slider):
                result.append(
                    "Slider: \(slider.title) Value: \(slider.value) " +
                        "Range: \(slider.range.description) Step: \(slider.step)"
                )
            case let .stepper(stepper):
                result.append("Stepper: \(stepper.title) Value: \(stepper.value) Range: \(stepper.range)")
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
