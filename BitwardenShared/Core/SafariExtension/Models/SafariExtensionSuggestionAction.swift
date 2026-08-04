// MARK: - SafariExtensionSuggestionAction

/// The primary action the Safari extension UI should suggest for a given request.
public enum SafariExtensionSuggestionAction: String, Codable, Equatable {
    case none
    case fill
    case saveLogin
    case updatePassword
    case generatePassword

    public static func from(_ request: SafariExtensionRequest) -> Self {
        if request.canAutofill {
            return .fill
        }
        if request.canSaveLogin {
            return .saveLogin
        }
        if request.canChangePassword {
            return .updatePassword
        }
        if request.canGeneratePassword {
            return .generatePassword
        }
        return .none
    }
}
