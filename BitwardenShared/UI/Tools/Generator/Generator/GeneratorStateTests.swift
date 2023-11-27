import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class GeneratorStateTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `formSections` returns the sections and fields for generating a passphrase.
    func test_formSections_passphrase() {
        var subject = GeneratorState()
        subject.passwordState.passwordGeneratorType = .passphrase

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Password
                Options: Password, Username
            Section: Options
              Menu: Password type
                Selection: Passphrase
                Options: Password, Passphrase
              Stepper: Number of words Value: 3 Range: 3...20
              Text: Word separator Value: -
              Toggle: Capitalize Value: false
              Toggle: Include number Value: false
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a passphrase.
    func test_formSections_passphrase_withoutTypeField() {
        var subject = GeneratorState()
        subject.passwordState.passwordGeneratorType = .passphrase
        subject.presentationMode = .inPlace

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
            Section: Options
              Menu: Password type
                Selection: Passphrase
                Options: Password, Passphrase
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
              Menu: What would you like to generate?
                Selection: Password
                Options: Password, Username
            Section: Options
              Menu: Password type
                Selection: Password
                Options: Password, Passphrase
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

    /// `formSections` returns the sections and fields for generating a password.
    func test_formSections_password_withoutTypeField() {
        var subject = GeneratorState()
        subject.passwordState.passwordGeneratorType = .password
        subject.presentationMode = .inPlace

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
            Section: Options
              Menu: Password type
                Selection: Password
                Options: Password, Passphrase
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

    /// `formSections` returns the sections and fields for generating a catch-all email username.
    func test_formSections_username_catchAllEmail() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .catchAllEmail

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Catch-all email
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Use your domain's configured catch-all inbox.
              Text: Domain name (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a catch-all email username.
    func test_formSections_username_catchAllEmail_withoutTypeField() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .catchAllEmail
        subject.presentationMode = .inPlace

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
            Section: Options
              Menu: Username type
                Selection: Catch-all email
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Use your domain's configured catch-all inbox.
              Text: Domain name (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a forwarded email alias using addy.io.
    func test_formSections_username_forwardedEmail_addyIO() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .forwardedEmail
        subject.usernameState.forwardedEmailService = .addyIO

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Forwarded email alias
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Generate an email alias with an external forwarding service.
              Menu: Service
                Selection: addy.io
                Options: addy.io, DuckDuckGo, Fastmail, Firefox Relay, SimpleLogin
              Text: API access token Value: (empty)
              Text: Domain name (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a forwarded email alias using DuckDuckGo.
    func test_formSections_username_forwardedEmail_duckDuckGo() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .forwardedEmail
        subject.usernameState.forwardedEmailService = .duckDuckGo

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Forwarded email alias
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Generate an email alias with an external forwarding service.
              Menu: Service
                Selection: DuckDuckGo
                Options: addy.io, DuckDuckGo, Fastmail, Firefox Relay, SimpleLogin
              Text: API key (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a forwarded email alias using Fastmail.
    func test_formSections_username_forwardedEmail_fastmail() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .forwardedEmail
        subject.usernameState.forwardedEmailService = .fastmail

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Forwarded email alias
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Generate an email alias with an external forwarding service.
              Menu: Service
                Selection: Fastmail
                Options: addy.io, DuckDuckGo, Fastmail, Firefox Relay, SimpleLogin
              Text: API key (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a forwarded email alias using Firefox Relay.
    func test_formSections_username_forwardedEmail_firefoxRelay() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .forwardedEmail
        subject.usernameState.forwardedEmailService = .firefoxRelay

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Forwarded email alias
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Generate an email alias with an external forwarding service.
              Menu: Service
                Selection: Firefox Relay
                Options: addy.io, DuckDuckGo, Fastmail, Firefox Relay, SimpleLogin
              Text: API access token Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a forwarded email alias using SimpleLogin.
    func test_formSections_username_forwardedEmail_simpleLogin() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .forwardedEmail
        subject.usernameState.forwardedEmailService = .simpleLogin

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Forwarded email alias
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Generate an email alias with an external forwarding service.
              Menu: Service
                Selection: SimpleLogin
                Options: addy.io, DuckDuckGo, Fastmail, Firefox Relay, SimpleLogin
              Text: API key (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a plus-address email username.
    func test_formSections_username_plusAddressedEmail() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .plusAddressedEmail

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Plus addressed email
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Use your email provider's subaddress capabilities
              Text: Email (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a plus-address email username.
    func test_formSections_username_plusAddressedEmail_withoutTypeField() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .plusAddressedEmail
        subject.presentationMode = .inPlace

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
            Section: Options
              Menu: Username type
                Selection: Plus addressed email
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
                Footer: Use your email provider's subaddress capabilities
              Text: Email (required) Value: (empty)
            """
        }
    }

    /// `formSections` returns the sections and fields for generating a random word username.
    func test_formSections_username_randomWord() {
        var subject = GeneratorState()
        subject.generatorType = .username
        subject.usernameState.usernameGeneratorType = .randomWord

        assertInlineSnapshot(of: dumpFormSections(subject.formSections), as: .lines) {
            """
            Section: (empty)
              Generated: (empty)
              Menu: What would you like to generate?
                Selection: Username
                Options: Password, Username
            Section: Options
              Menu: Username type
                Selection: Random word
                Options: Plus addressed email, Catch-all email, Forwarded email alias, Random word
              Toggle: Capitalize Value: false
              Toggle: Include number Value: false
            """
        }
    }

    /// `passwordState.passphraseGeneratorRequest` returns the passphrase generator request.
    func test_passwordState_passphraseGeneratorRequest() {
        var subject = GeneratorState().passwordState

        XCTAssertEqual(
            subject.passphraseGeneratorRequest,
            PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: false,
                includeNumber: false
            )
        )

        subject.numberOfWords = 6
        subject.wordSeparator = "*"
        subject.capitalize = true
        subject.includeNumber = true

        XCTAssertEqual(
            subject.passphraseGeneratorRequest,
            PassphraseGeneratorRequest(
                numWords: 6,
                wordSeparator: "*",
                capitalize: true,
                includeNumber: true
            )
        )
    }

    /// `passwordState.passwordGeneratorRequest` returns the password generator request.
    func test_passwordState_passwordGeneratorRequest() {
        var subject = GeneratorState().passwordState

        XCTAssertEqual(
            subject.passwordGeneratorRequest,
            PasswordGeneratorRequest(
                lowercase: true,
                uppercase: true,
                numbers: true,
                special: false,
                length: 14,
                avoidAmbiguous: false,
                minLowercase: nil,
                minUppercase: nil,
                minNumber: nil,
                minSpecial: nil
            )
        )

        subject.containsLowercase = false
        subject.containsUppercase = false
        subject.containsNumbers = false
        subject.containsSpecial = true
        subject.length = 30
        subject.avoidAmbiguous = true

        XCTAssertEqual(
            subject.passwordGeneratorRequest,
            PasswordGeneratorRequest(
                lowercase: false,
                uppercase: false,
                numbers: false,
                special: true,
                length: 30,
                avoidAmbiguous: true,
                minLowercase: nil,
                minUppercase: nil,
                minNumber: nil,
                minSpecial: nil
            )
        )
    }

    /// `passwordState.validateOptions()` doesn't change any options if they are already valid.
    func test_passwordState_validateOptions_isValid() {
        var subject = GeneratorState().passwordState

        let subjectBeforeValidation = subject
        subject.validateOptions()

        XCTAssertEqual(subject, subjectBeforeValidation)
    }

    /// `passwordState.validateOptions()` enables lowercase characters if all character set toggled
    /// have been turned off.
    func test_passwordState_validateOptions_allCharacterSetsOff() {
        var subject = GeneratorState().passwordState

        subject.containsLowercase = false
        subject.containsNumbers = false
        subject.containsSpecial = false
        subject.containsUppercase = false

        var subjectWithLowercaseEnabled = subject
        subjectWithLowercaseEnabled.containsLowercase = true

        subject.validateOptions()

        XCTAssertEqual(subject, subjectWithLowercaseEnabled)
    }

    /// `passwordState.validateOptions()` sets the length based on the minimum length calculated
    /// based on the enabled options.
    func test_passwordState_validateOptions_minimumLength() {
        var subject = GeneratorState().passwordState

        subject.containsNumbers = false
        subject.containsSpecial = false
        subject.containsUppercase = false
        subject.minimumNumber = 5
        subject.minimumSpecial = 5
        subject.length = 5

        subject.validateOptions()
        XCTAssertEqual(subject.length, 5)

        subject.containsNumbers = true
        subject.validateOptions()
        XCTAssertEqual(subject.length, 6)

        subject.containsSpecial = true
        subject.validateOptions()
        XCTAssertEqual(subject.length, 11)

        // Decreasing `minimumNumber` doesn't change the length.
        subject.minimumNumber = 1
        subject.validateOptions()
        XCTAssertEqual(subject.length, 11)

        subject.length = 5
        subject.validateOptions()
        XCTAssertEqual(subject.length, 7)
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
                result.append(menu.dumpField(indent: indent))
            case let .menuPasswordGeneratorType(menu):
                result.append(menu.dumpField(indent: indent))
            case let .menuUsernameForwardedEmailService(menu):
                result.append(menu.dumpField(indent: indent))
            case let .menuUsernameGeneratorType(menu):
                result.append(menu.dumpField(indent: indent))
            case let .slider(slider):
                result.append(
                    "Slider: \(slider.title) Value: \(slider.value) " +
                        "Range: \(slider.range.description) Step: \(slider.step)"
                )
            case let .stepper(stepper):
                result.append("Stepper: \(stepper.title) Value: \(stepper.value) Range: \(stepper.range)")
            case let .text(text):
                result.append("Text: \(text.title) Value: \(text.value.isEmpty ? "(empty)" : text.value)")
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

private extension FormMenuField {
    /// Returns a string containing a description of the `FormMenuField`.
    func dumpField(indent: String) -> String {
        [
            "Menu: \(title)",
            indent + "  Selection: \(selection.localizedName)",
            indent + "  Options: \(options.map(\.localizedName).joined(separator: ", "))",
            footer.map { indent + "  Footer: \($0)" },
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }
}
