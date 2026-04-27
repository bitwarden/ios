import Foundation

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
            if let normalizedOldPassword {
                let normalizedMatchedPassword = matchedLogin.password?.trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalizedOldPassword == normalizedMatchedPassword else {
                    return .none
                }
            }

            return .updatePassword
        }

        if request.kind == .saveLogin, !(request.password?.isEmpty ?? true) {
            guard let matchedLogin else {
                return .saveNewLogin
            }

            let normalizedRequestUsername = request.username?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedMatchedUsername = matchedLogin.username?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedRequestPassword = request.password?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedMatchedPassword = matchedLogin.password?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedRequestURL = request.urlString?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedMatchedURL = matchedLogin.urlString?.trimmingCharacters(in: .whitespacesAndNewlines)

            if normalizedRequestUsername == nil {
                if !saveLoginURLsAppearEquivalent(
                    requestURLString: normalizedRequestURL,
                    matchedURLString: normalizedMatchedURL
                ) {
                    return .saveNewLogin
                }

                if normalizedRequestPassword != normalizedMatchedPassword {
                    return .updateExistingLogin
                }

                return .none
            }

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

    private static func saveLoginURLsAppearEquivalent(
        requestURLString: String?,
        matchedURLString: String?
    ) -> Bool {
        guard let request = normalizedSaveLoginURLContext(from: requestURLString),
              let matched = normalizedSaveLoginURLContext(from: matchedURLString) else {
            return requestURLString == matchedURLString
        }

        guard request.scheme == matched.scheme,
              request.host == matched.host,
              request.port == matched.port else {
            return false
        }

        if request.normalizedPath == matched.normalizedPath {
            return true
        }

        return request.isLoginLikePath && matched.isLoginLikePath
    }

    private static func normalizedSaveLoginURLContext(from urlString: String?) -> SaveLoginURLContext? {
        guard let urlString,
              let components = URLComponents(string: urlString),
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased() else {
            return nil
        }

        let normalizedPath = normalizedSaveLoginPath(components.path)
        return SaveLoginURLContext(
            scheme: scheme,
            host: host,
            port: components.port,
            normalizedPath: normalizedPath,
            isLoginLikePath: isLoginLikePath(normalizedPath)
        )
    }

    private static func normalizedSaveLoginPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "/" else {
            return "/"
        }

        let collapsed = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        return collapsed.hasSuffix("/") && collapsed.count > 1 ? String(collapsed.dropLast()) : collapsed
    }

    private static func isLoginLikePath(_ path: String) -> Bool {
        let loginLikeTokens = ["login", "log-in", "signin", "sign-in", "auth"]
        return loginLikeTokens.contains { path.localizedCaseInsensitiveContains($0) }
    }
}

private struct SaveLoginURLContext {
    var scheme: String
    var host: String
    var port: Int?
    var normalizedPath: String
    var isLoginLikePath: Bool
}
