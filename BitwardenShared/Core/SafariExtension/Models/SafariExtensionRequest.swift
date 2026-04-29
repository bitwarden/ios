import Foundation

// MARK: - SafariExtensionRequestKind

/// The high-level action requested by the Safari extension host/content bridge.
public enum SafariExtensionRequestKind: String, Codable, Equatable {
    case setup
    case fill
    case saveLogin
    case changePassword
    case generatePassword
}

// MARK: - SafariExtensionRequestTrigger

/// The originating UX trigger for a Safari extension request.
public enum SafariExtensionRequestTrigger: String, Codable, Equatable {
    case suggestedAction
    case actionPanelPrimary
    case setupButton
}

// MARK: - SafariExtensionRequestContext

/// Additional product-level context about how a Safari extension request was initiated.
public struct SafariExtensionRequestContext: Codable, Equatable {
    var trigger: SafariExtensionRequestTrigger
    var submissionAction: SafariExtensionSubmissionAction?
}

// MARK: - SafariExtensionRequest

/// A shared Codable payload for Safari extension requests flowing between web/native layers.
public struct SafariExtensionRequest: Codable, Equatable {
    /// The requested action type.
    public var kind: SafariExtensionRequestKind

    /// The login title extracted from the page, if any.
    var loginTitle: String?

    /// Notes extracted from the page or flow, if any.
    var notes: String?

    /// The previous password for change-password flows.
    var oldPassword: String?

    /// Additional metadata about how the request was initiated.
    var requestContext: SafariExtensionRequestContext?

    /// Parsed page details for page-aware fill/save/update flows.
    var pageDetails: PageDetails?

    /// The current or generated password value.
    var password: String?

    /// Password generation options associated with the page/action.
    var passwordOptions: PasswordGenerationOptions?

    /// The page URL used for matching and save/update suggestions.
    var urlString: String?

    /// The username extracted from the page, if any.
    var username: String?

    /// Whether this request can drive page-aware autofill.
    public var canAutofill: Bool {
        kind == .fill && pageDetails?.hasPasswordField == true
    }

    /// Whether this request contains enough information to save a login.
    public var canSaveLogin: Bool {
        kind == .saveLogin && !(username?.isEmpty ?? true) && !(password?.isEmpty ?? true)
    }

    /// Whether this request contains enough information to update a password.
    public var canChangePassword: Bool {
        kind == .changePassword && !(password?.isEmpty ?? true)
    }

    /// Whether this request can drive password generation UI.
    public var canGeneratePassword: Bool {
        kind == .generatePassword
    }

    public init(kind: SafariExtensionRequestKind) {
        self.init(
            kind: kind,
            loginTitle: nil,
            notes: nil,
            oldPassword: nil,
            requestContext: nil,
            pageDetails: nil,
            password: nil,
            passwordOptions: nil,
            urlString: nil,
            username: nil,
        )
    }

    init(
        kind: SafariExtensionRequestKind,
        loginTitle: String? = nil,
        notes: String? = nil,
        oldPassword: String? = nil,
        requestContext: SafariExtensionRequestContext? = nil,
        pageDetails: PageDetails? = nil,
        password: String? = nil,
        passwordOptions: PasswordGenerationOptions? = nil,
        urlString: String? = nil,
        username: String? = nil,
    ) {
        self.kind = kind
        self.loginTitle = loginTitle
        self.notes = notes
        self.oldPassword = oldPassword
        self.requestContext = requestContext
        self.pageDetails = pageDetails
        self.password = password
        self.passwordOptions = passwordOptions
        self.urlString = urlString
        self.username = username
    }
}
