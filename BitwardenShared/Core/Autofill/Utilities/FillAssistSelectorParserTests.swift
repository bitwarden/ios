import Testing

@testable import BitwardenShared

// MARK: - FillAssistSelectorParserTests

struct FillAssistSelectorParserTests {
    // MARK: Tests - Tag Extraction

    /// `parse(_:)` extracts the leading tag name from a selector.
    @Test
    func parse_tagName() {
        #expect(FillAssistSelectorParser.parse("input#user")?.tagName == "input")
        #expect(FillAssistSelectorParser.parse("button[type=submit]")?.tagName == "button")
        #expect(FillAssistSelectorParser.parse("[name=email]")?.tagName == nil)
    }

    // MARK: Tests - ID Extraction

    /// `parse(_:)` extracts `id` from a double-quoted attribute selector.
    @Test
    func parse_idAttributeDoubleQuoted() {
        #expect(FillAssistSelectorParser.parse(#"input[id="login-email"]"#)?.id == "login-email")
    }

    /// `parse(_:)` extracts `id` from a single-quoted attribute selector.
    @Test
    func parse_idAttributeSingleQuoted() {
        #expect(FillAssistSelectorParser.parse("input[id='login-email']")?.id == "login-email")
    }

    /// `parse(_:)` extracts the `#id` shorthand.
    @Test
    func parse_idShorthand() {
        #expect(FillAssistSelectorParser.parse("#login-email")?.id == "login-email")
        #expect(FillAssistSelectorParser.parse("input#user")?.id == "user")
    }

    // MARK: Tests - Unquoted Attribute Values

    /// `parse(_:)` extracts `name` from an unquoted attribute selector.
    @Test
    func parse_nameAttributeUnquoted() {
        #expect(FillAssistSelectorParser.parse("input[name=username]")?.name == "username")
    }

    /// `parse(_:)` extracts `role` from an unquoted attribute selector.
    @Test
    func parse_roleAttributeUnquoted() {
        #expect(FillAssistSelectorParser.parse("div[role=button]")?.role == "button")
    }

    /// `parse(_:)` extracts attribute values when quotes are absent — e.g. `button[type=submit]`.
    @Test
    func parse_unquotedAttributeValue() {
        #expect(FillAssistSelectorParser.parse("input[type=email]")?.type == "email")
    }

    // MARK: Tests - Hyphenated Attribute Names

    /// `parse(_:)` handles hyphenated attribute names such as `data-type` without crashing —
    /// unknown attributes are captured by the regex but not assigned to known fields.
    @Test
    func parse_hyphenatedAttributeName() {
        #expect(FillAssistSelectorParser.parse("input[data-name=email]")?.tagName == "input")
    }

    // MARK: Tests - Exclusions

    /// `parse(_:)` returns `nil` for class-only selectors.
    @Test
    func parse_classOnly_returnsNil() {
        #expect(FillAssistSelectorParser.parse(".login-field") == nil)
    }

    /// `parse(_:)` returns `nil` when no useful attributes are found.
    @Test
    func parse_noAttributes_returnsNil() {
        #expect(FillAssistSelectorParser.parse("") == nil)
    }

    /// `parse(_:)` returns `nil` for shadow DOM selectors.
    @Test
    func parse_shadowDom_returnsNil() {
        #expect(FillAssistSelectorParser.parse("div >>> input[name=email]") == nil)
    }
}
