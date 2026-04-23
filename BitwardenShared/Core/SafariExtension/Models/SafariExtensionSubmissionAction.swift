// MARK: - SafariExtensionMatchedLogin

/// A lightweight snapshot of an existing matching login item.
public struct SafariExtensionMatchedLogin: Codable, Equatable {
    var id: String
    var username: String?
    var password: String?
    var urlString: String?
}

// MARK: - SafariExtensionSubmissionAction

/// The action the native layer should take when deciding between save/update flows.
public enum SafariExtensionSubmissionAction: String, Codable, Equatable {
    case none
    case fill
    case saveNewLogin
    case updateExistingLogin
    case updatePassword
    case generatePassword

    public static func classify(
        _ request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
    ) -> Self {
        if request.canAutofill {
            return .fill
        }

        if request.canGeneratePassword {
            return .generatePassword
        }

        if request.canChangePassword {
            guard let matchedLogin else {
                return .none
            }

            let normalizedOldPassword = request.oldPassword?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedMatchedPassword = matchedLogin.password?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard normalizedOldPassword == normalizedMatchedPassword else {
                return .none
            }

            return .updatePassword
        }

        if request.canSaveLogin {
            guard let matchedLogin else {
                return .saveNewLogin
            }

            let normalizedRequestUsername = request.username?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedMatchedUsername = matchedLogin.username?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedRequestPassword = request.password?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedMatchedPassword = matchedLogin.password?.trimmingCharacters(in: .whitespacesAndNewlines)

            if normalizedRequestUsername != normalizedMatchedUsername {
                return .saveNewLogin
            }

            if normalizedRequestPassword != normalizedMatchedPassword {
                return .updateExistingLogin
            }

            return .none
        }

        return .none
    }
}
