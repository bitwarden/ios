// MARK: - FillScript

/// Builds a `Codable` type that can be converted to JSON and sent back to the fill script to
/// autofill any fields on a web page.
///
struct FillScript: Codable {
    // MARK: Type Properties

    /// A list of username field names.
    private static let usernameFieldNames = [
        "username",
        "user name",
        "email",
        "email address",
        "e-mail",
        "e-mail address",
        "userid",
        "user id",
    ]

    // MARK: Properties

    /// The document's UUID.
    var documentUUID: String

    /// Metadata to pass to the script.
    var metadata = [String]()

    /// Options to pass to the script.
    var options = [String]()

    /// Properties to pass to the script.
    var properties = [String]()

    /// Actions to take by the script to autofill the fields.
    var script = [[String]]()

    // MARK: Initialization

    /// Initialize a `FillScript`.
    ///
    /// - Parameters:
    ///   - pageDetails: The parsed details of the web page.
    ///   - fillUsername: The username to autofill.
    ///   - fillPassword: The password to autofill.
    ///   - fillFields: Additional fields to autofill.
    ///
    init( // swiftlint:disable:this cyclomatic_complexity function_body_length
        pageDetails: PageDetails?,
        fillUsername: String,
        fillPassword: String,
        fillFields: [(String, String)]
    ) {
        guard let pageDetails else { documentUUID = ""; return }

        documentUUID = pageDetails.documentUUID

        var filledFields = [String: PageDetails.Field]()

        if !fillFields.isEmpty {
            let fieldNames = fillFields.map { $0.0.lowercased() }
            for field in pageDetails.fields where field.viewable {
                if filledFields.keys.contains(field.opId) {
                    continue
                }

                let matchingIndex = findMatchingFieldIndex(field: field, names: fieldNames)
                if matchingIndex > -1 {
                    filledFields[field.opId] = field
                    script.append(["click_on_opid", field.opId])
                    script.append(["fill_by_opid", field.opId, fillFields[matchingIndex].1])
                }
            }
        }

        if fillPassword.isEmpty {
            // No password for this login. Maybe they just wanted to auto-fill some custom fields?
            setFillScriptForFocus(filledFields: filledFields)
            return
        }

        var usernames = [PageDetails.Field]()
        var passwords = [PageDetails.Field]()

        var passwordFields = pageDetails.fields.filter { $0.type == "password" && $0.viewable }
        if passwordFields.isEmpty {
            // Not able to find any viewable password fields. maybe there are some "hidden" ones?
            passwordFields = pageDetails.fields.filter { $0.type == "password" }
        }

        for form in pageDetails.forms {
            let passwordFieldsForForm = passwordFields.filter { $0.form == form.key }
            passwords.append(contentsOf: passwordFieldsForForm)

            guard !fillUsername.isEmpty else { continue }

            for passwordField in passwordFieldsForForm {
                var username = findUsernameField(
                    pageDetails: pageDetails,
                    passwordField: passwordField,
                    canBeHidden: false,
                    checkForm: true
                )
                if username == nil {
                    // not able to find any viewable username fields. maybe there are some "hidden" ones?
                    username = findUsernameField(
                        pageDetails: pageDetails,
                        passwordField: passwordField,
                        canBeHidden: true,
                        checkForm: true
                    )
                }

                if let username {
                    usernames.append(username)
                }
            }
        }

        if !passwordFields.isEmpty, passwords.isEmpty {
            // The page does not have any forms with password fields. Use the first password field on the page and the
            // input field just before it as the username.
            if let passwordField = passwordFields.first {
                passwords.append(passwordField)

                if !fillUsername.isEmpty, passwordField.elementNumber > 0 {
                    var username = findUsernameField(
                        pageDetails: pageDetails,
                        passwordField: passwordField,
                        canBeHidden: false,
                        checkForm: false
                    )
                    if username == nil {
                        // not able to find any viewable username fields. maybe there are some "hidden" ones?
                        username = findUsernameField(
                            pageDetails: pageDetails,
                            passwordField: passwordField,
                            canBeHidden: true,
                            checkForm: false
                        )
                    }

                    if let username {
                        usernames.append(username)
                    }
                }
            }
        }

        if passwordFields.isEmpty {
            // No password fields on this page. Let's try to just fuzzy fill the username.
            let usernameFieldNamesList = Self.usernameFieldNames
            for field in pageDetails.fields {
                if field.viewable,
                   field.type == "text" || field.type == "email" || field.type == "tel",
                   fieldIsFuzzyMatch(field: field, names: usernameFieldNamesList) {
                    usernames.append(field)
                }
            }
        }

        for username in usernames where !filledFields.keys.contains(username.opId) {
            filledFields[username.opId] = username
            script.append(["click_on_opid", username.opId])
            script.append(["fill_by_opid", username.opId, fillUsername])
        }

        for password in passwords where !filledFields.keys.contains(password.opId) {
            filledFields[password.opId] = password
            script.append(["click_on_opid", password.opId])
            script.append(["fill_by_opid", password.opId, fillPassword])
        }

        setFillScriptForFocus(filledFields: filledFields)
    }

    // MARK: Private

    /// Finds the username field within the page details.
    ///
    /// - Parameters:
    ///   - pageDetails: The parsed details of the web page.
    ///   - passwordField: The password field.
    ///   - canBeHidden: Whether the field can be hidden.
    ///   - checkForm: Whether to check the form for the field.
    ///
    /// - Returns: The username field.
    ///
    private func findUsernameField(
        pageDetails: PageDetails,
        passwordField: PageDetails.Field,
        canBeHidden: Bool,
        checkForm: Bool
    ) -> PageDetails.Field? {
        var usernameField: PageDetails.Field?

        for field in pageDetails.fields {
            if field.elementNumber >= passwordField.elementNumber {
                break
            }

            if !checkForm || field.form == passwordField.form,
               canBeHidden || field.viewable,
               field.elementNumber < passwordField.elementNumber,
               field.type == "text" || field.type == "email" || field.type == "tel" {
                usernameField = field

                if findMatchingFieldIndex(field: field, names: Self.usernameFieldNames) > -1 {
                    // We found an exact match. No need to keep looking.
                    break
                }
            }
        }

        return usernameField
    }

    /// Finds the matching index in the list of names that matches the field.
    ///
    /// - Parameters:
    ///   - field: The field to find a matching name.
    ///   - names: The list of names to match to the field.
    /// - Returns: The index of the name matching the field, or -1 if no match was found.
    ///
    private func findMatchingFieldIndex(field: PageDetails.Field, names: [String?]) -> Int {
        var matchingIndex = -1
        if let htmlId = field.htmlId, !htmlId.isEmpty {
            matchingIndex = names.firstIndex(of: htmlId.lowercased()) ?? -1
        }
        if matchingIndex < 0, let htmlName = field.htmlName, !htmlName.isEmpty {
            matchingIndex = names.firstIndex(of: htmlName.lowercased()) ?? -1
        }
        if matchingIndex < 0, let labelTag = field.labelTag, !labelTag.isEmpty {
            matchingIndex = names.firstIndex(of: cleanLabel(label: labelTag)) ?? -1
        }
        if matchingIndex < 0, let placeholder = field.placeholder, !placeholder.isEmpty {
            matchingIndex = names.firstIndex(of: placeholder.lowercased()) ?? -1
        }

        return matchingIndex
    }

    /// Determines whether a field is a fuzzy match to one of the names in the list.
    ///
    /// - Parameters:
    ///   - field: The field to find a matching name.
    ///   - names: The list of names to fuzzy match to the field.
    /// - Returns: Whether a match was found.
    ///
    private func fieldIsFuzzyMatch(field: PageDetails.Field, names: [String]) -> Bool {
        if let htmlId = field.htmlId,
           !htmlId.isEmpty,
           fuzzyMatch(options: names, value: htmlId.lowercased()) {
            return true
        }
        if let htmlName = field.htmlName,
           !htmlName.isEmpty,
           fuzzyMatch(options: names, value: htmlName.lowercased()) {
            return true
        }
        if let labelTag = field.labelTag,
           !labelTag.isEmpty,
           fuzzyMatch(options: names, value: cleanLabel(label: labelTag)) {
            return true
        }
        if let placeholder = field.placeholder,
           !placeholder.isEmpty,
           fuzzyMatch(options: names, value: placeholder.lowercased()) {
            return true
        }

        return false
    }

    /// Determines if a value fuzzy matches against a list of options.
    ///
    /// - Parameters:
    ///   - options: The list of options to fuzzy match against.
    ///   - value: The value to match.
    /// - Returns: Whether the value is a fuzzy match against the list of options.
    ///
    private func fuzzyMatch(options: [String], value: String) -> Bool {
        guard !options.isEmpty, !value.isEmpty else { return false }
        return options.contains { value.contains($0) }
    }

    /// Adds a script element to focus on a field.
    ///
    /// - Parameter filledFields: The dictionary of fields that will be filled.
    ///
    private mutating func setFillScriptForFocus(filledFields: [String: PageDetails.Field]) {
        guard !filledFields.isEmpty else { return }

        var lastField: PageDetails.Field?
        var lastPasswordField: PageDetails.Field?
        for field in filledFields.values where field.viewable {
            lastField = field
            if field.type == "password" {
                lastPasswordField = field
            }
        }

        // Prioritize password field over others.
        if let lastPasswordField {
            script.append(["focus_by_opid", lastPasswordField.opId])
        } else if let lastField {
            script.append(["focus_by_opid", lastField.opId])
        }
    }

    /// Sanitizes a label by removing any whitespace and newline characters.
    ///
    /// - Parameter label: The label to sanitize.
    /// - Returns: The sanitized label.
    ///
    private func cleanLabel(label: String) -> String {
        label.replacingOccurrences(of: "(?:\r\n|\r|\n)", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
