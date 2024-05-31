import LocalAuthentication
import OSLog

// MARK: - LocalAuthService

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol LocalAuthService: AnyObject {
    /// Evaluate's the users device owner policy
    /// - Parameters:
    ///   - suppliedContext: The `LAContext` to use (optional)
    ///   - deviceAuthStatus: The current `DeviceAuthenticationStatus`
    ///   - localizedReason: The  reason to be displayed to the user when evaluating the policy if needed
    /// - Returns: A `Bool` indicating if the evaluation was successful
    /// - Throws: Throws `LAError.Code.userCancel` if cancelled
    func evaluateDeviceOwnerPolicy(
        _ suppliedContext: LAContext?,
        for deviceAuthStatus: DeviceAuthenticationStatus,
        because localizedReason: String
    ) async throws -> Bool

    /// Returns the status for user device authentication.
    ///
    /// - Parameter suppliedContext: The `LAContext` to use (optional).
    /// - Returns: The a `DeviceAuthenticationStatus`.
    ///
    func getDeviceAuthStatus(_ suppliedContext: LAContext?) -> DeviceAuthenticationStatus
}

// MARK: - LocalAuthService

extension LocalAuthService {
    /// Returns the status for user device authentication.
    ///
    /// - Parameter suppliedContext: The `LAContext` to use (optional).
    /// - Returns: The a `DeviceAuthenticationStatus`.
    ///
    func getDeviceAuthStatus() -> DeviceAuthenticationStatus {
        getDeviceAuthStatus(nil)
    }

    /// Evaluate's the users biometrics policy via `BiometricAuthorizationStatus`
    /// - Parameters:
    ///   - suppliedContext: The `LAContext` to use (optional).
    ///   - localizedReason: The  reason to be displayed to the user when evaluating the policy if needed
    /// - Returns: An evaluated status for the user's biometric authorization.
    /// - Throws: Throws `LAError.Code.userCancel` if cancelled
    func evaluateDeviceOwnerPolicy(
        _ suppliedContext: LAContext? = nil,
        because localizedReason: String
    ) async throws -> Bool {
        let initialStatus = getDeviceAuthStatus(suppliedContext)
        return try await evaluateDeviceOwnerPolicy(suppliedContext, for: initialStatus, because: localizedReason)
    }
}

// MARK: - DefaultLocalAuthService

class DefaultLocalAuthService: LocalAuthService {
    func getDeviceAuthStatus(_ suppliedContext: LAContext?) -> DeviceAuthenticationStatus {
        let authContext = suppliedContext ?? LAContext()
        var error: NSError?

        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            guard let error else {
                return .notDetermined
            }

            guard let laError = error as? LAError else {
                // A non LAError occured
                Logger.application.log("Other error: \(error.localizedDescription)")
                return .unknownError(error.localizedDescription)
            }

            switch laError.code {
            case .userCancel:
                Logger.application.log("User cancel authentication")
                return .cancelled
            case .passcodeNotSet:
                Logger.application.log("Passcode not set")
                return .passcodeNotSet
            default:
                Logger.application.log("Other error: \(laError.localizedDescription)")
                return .unknownError(laError.localizedDescription)
            }
        }

        return .authorized
    }

    func evaluateDeviceOwnerPolicy(
        _ suppliedContext: LAContext?,
        for deviceAuthStatus: DeviceAuthenticationStatus,
        because localizedReason: String
    ) async throws -> Bool {
        guard case .authorized = deviceAuthStatus else {
            return false
        }

        let authContext = suppliedContext ?? LAContext()

        do {
            let result = try await authContext.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: localizedReason
            )
            return result
        } catch LAError.userCancel {
            throw LocalAuthError.cancelled
        } catch {
            Logger.processor.error("Error evaluating device owner policy: \(error)")
            return false
        }
    }
}

// MARK: - LocalAuthError

/// Errors corresponding to Local Auth operations.
///
public enum LocalAuthError: Error {
    case cancelled
}
