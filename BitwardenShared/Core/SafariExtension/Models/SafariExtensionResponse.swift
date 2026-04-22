import Foundation

// MARK: - SafariExtensionResponse

/// A shared Codable payload returned from the native Safari extension layer back to the web bridge/UI.
struct SafariExtensionResponse: Codable, Equatable {
    /// The originating request.
    var request: SafariExtensionRequest

    /// The high-level action the UI should present.
    var suggestionAction: SafariExtensionSuggestionAction

    /// The concrete native submission action selected for the request.
    var submissionAction: SafariExtensionSubmissionAction

    /// A matching login, when one was found in the vault.
    var matchedLogin: SafariExtensionMatchedLogin?

    /// The encoded fill script JSON to send back into the page, when available.
    var fillScriptJSON: String?

    /// A generated password to offer back to the page, when available.
    var generatedPassword: String?

    /// Optional user-facing copy for setup/save/update flows.
    var userMessage: String?

    /// Whether the response includes a fill script that can be finalized into the page.
    var canFinalizeWithScript: Bool {
        submissionAction == .fill && !(fillScriptJSON?.isEmpty ?? true)
    }

    /// Whether the response includes a generated password payload.
    var hasGeneratedPassword: Bool {
        !(generatedPassword?.isEmpty ?? true)
    }

    /// Build a response for page fill flows.
    static func fill(
        request: SafariExtensionRequest,
        username: String,
        password: String,
        fields: [(String, String)],
        matchedLogin: SafariExtensionMatchedLogin?,
    ) throws -> Self {
        guard request.canAutofill else {
            throw CocoaError(.coderInvalidValue)
        }

        let fillScript = FillScript(
            pageDetails: request.pageDetails,
            fillUsername: username,
            fillPassword: password,
            fillFields: fields,
        )
        let fillScriptData = try JSONEncoder().encode(fillScript)
        guard let fillScriptJSON = String(data: fillScriptData, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return Self(
            request: request,
            suggestionAction: SafariExtensionSuggestionAction.from(request),
            submissionAction: SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin),
            matchedLogin: matchedLogin,
            fillScriptJSON: fillScriptJSON,
            generatedPassword: nil,
            userMessage: nil,
        )
    }

    /// Build a response for password generation flows.
    static func generatedPassword(_ generatedPassword: String, for request: SafariExtensionRequest) throws -> Self {
        guard request.canGeneratePassword else {
            throw CocoaError(.coderInvalidValue)
        }

        return Self(
            request: request,
            suggestionAction: SafariExtensionSuggestionAction.from(request),
            submissionAction: SafariExtensionSubmissionAction.classify(request, matchedLogin: nil),
            matchedLogin: nil,
            fillScriptJSON: nil,
            generatedPassword: generatedPassword,
            userMessage: nil,
        )
    }
}
