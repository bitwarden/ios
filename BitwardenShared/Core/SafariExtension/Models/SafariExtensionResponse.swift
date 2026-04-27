import Foundation

// MARK: - SafariExtensionResponseFollowUpType

/// Additional context for action-panel flows that follow a previous response.
public enum SafariExtensionResponseFollowUpType: String, Codable, Equatable {
    case generatedPassword
}

// MARK: - SafariExtensionResponse

/// A shared Codable payload returned from the native Safari extension layer back to the web bridge/UI.
public struct SafariExtensionResponse: Codable, Equatable {
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

    /// Additional context for flows that were triggered as a follow-up to another response.
    var followUpType: SafariExtensionResponseFollowUpType?

    /// A request to use for the next follow-up action, when the native layer already knows it.
    var followUpRequest: SafariExtensionRequest?

    /// The submission action to use for the next follow-up action, when the native layer already knows it.
    var followUpSubmissionAction: SafariExtensionSubmissionAction?

    /// Whether the response includes a fill script that can be finalized into the page.
    public var canFinalizeWithScript: Bool {
        submissionAction == .fill && !(fillScriptJSON?.isEmpty ?? true)
    }

    /// Whether the response includes a generated password payload.
    public var hasGeneratedPassword: Bool {
        !(generatedPassword?.isEmpty ?? true)
    }

    /// Build a response for page fill flows.
    public init(
        request: SafariExtensionRequest,
        suggestionAction: SafariExtensionSuggestionAction,
        submissionAction: SafariExtensionSubmissionAction,
        matchedLogin: SafariExtensionMatchedLogin?,
        fillScriptJSON: String?,
        generatedPassword: String?,
        userMessage: String?,
        followUpType: SafariExtensionResponseFollowUpType? = nil,
        followUpRequest: SafariExtensionRequest? = nil,
        followUpSubmissionAction: SafariExtensionSubmissionAction? = nil,
    ) {
        self.request = request
        self.suggestionAction = suggestionAction
        self.submissionAction = submissionAction
        self.matchedLogin = matchedLogin
        self.fillScriptJSON = fillScriptJSON
        self.generatedPassword = generatedPassword
        self.userMessage = userMessage
        self.followUpType = followUpType
        self.followUpRequest = followUpRequest
        self.followUpSubmissionAction = followUpSubmissionAction
    }

    /// Build a response for page fill flows.
    public static func fill(
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
            userMessage: fillCompletionMessage(request: request, matchedLogin: matchedLogin),
        )
    }

    private static func fillCompletionMessage(
        request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?
    ) -> String {
        if let username = matchedLogin?.username, !username.isEmpty {
            return "Filled \(username) from Bitwarden."
        }
        let host = matchedLogin?.urlString.flatMap { URL(string: $0)?.host }
            ?? request.urlString.flatMap { URL(string: $0)?.host }
        if let host, !host.isEmpty {
            return "Filled login for \(host) from Bitwarden."
        }
        return "Filled login from Bitwarden."
    }

    /// Build a response for password generation flows.
    public static func generatedPassword(
        _ generatedPassword: String,
        for request: SafariExtensionRequest,
        followUpType: SafariExtensionResponseFollowUpType? = nil,
        followUpRequest: SafariExtensionRequest? = nil,
        followUpSubmissionAction: SafariExtensionSubmissionAction? = nil
    ) throws -> Self {
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
            userMessage: "Generated password with Bitwarden.",
            followUpType: followUpType,
            followUpRequest: followUpRequest,
            followUpSubmissionAction: followUpSubmissionAction,
        )
    }
}
