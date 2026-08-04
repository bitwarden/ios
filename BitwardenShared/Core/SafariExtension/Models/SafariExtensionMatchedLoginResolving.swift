// MARK: - SafariExtensionResolvedContext

/// The request plus any matched login, after vault resolution has run.
struct SafariExtensionResolvedContext: Equatable {
    var request: SafariExtensionRequest
    var matchedLogin: SafariExtensionMatchedLogin?

    var suggestionAction: SafariExtensionSuggestionAction {
        SafariExtensionSuggestionAction.from(request)
    }

    var submissionAction: SafariExtensionSubmissionAction {
        SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin)
    }
}

// MARK: - SafariExtensionMatchedLoginResolving

/// Resolves an existing login match for Safari save/update/change-password flows.
protocol SafariExtensionMatchedLoginResolving {
    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin?
}

extension SafariExtensionMatchedLoginResolving {
    func resolveContext(for request: SafariExtensionRequest) async throws -> SafariExtensionResolvedContext {
        let matchedLogin = try await resolveMatchedLogin(for: request)
        return SafariExtensionResolvedContext(
            request: request,
            matchedLogin: matchedLogin,
        )
    }
}
