import Foundation

// MARK: - DefaultVaultTimeoutService + Session Timeout

/// `hasPassedSessionTimeout` and `timeUntilSessionTimeout`, split out of
/// `VaultTimeoutService.swift` to keep that file under the file length limit. Both share the
/// tamper-resistant elapsed-time calculation in `effectiveElapsedTime`.
///
extension DefaultVaultTimeoutService {
    func hasPassedSessionTimeout(userId: String, isAppRestart: Bool = false) async throws -> Bool {
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)
        switch vaultTimeout {
        case .never:
            return false
        case .onAppRestart:
            // On app restart, trigger timeout if this is actually an app restart
            return isAppRestart
        default:
            // If the elapsed time can't be determined (missing state, tampering, or a
            // reboot-timing attack), fail closed and treat the session as timed out.
            guard let elapsed = try await effectiveElapsedTime(userId: userId) else {
                return true
            }

            let timeoutSeconds = TimeInterval(vaultTimeout.seconds)
            return elapsed >= timeoutSeconds
        }
    }

    func timeUntilSessionTimeout(userId: String) async throws -> TimeInterval? {
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)
        guard vaultTimeout.allowsUserSessionKeySharing else { return nil }

        // If the elapsed time can't be determined (missing state, tampering, or a reboot-timing
        // attack), fail closed and treat the session as already timed out.
        guard let elapsed = try await effectiveElapsedTime(userId: userId) else {
            return 0
        }

        let timeoutSeconds = TimeInterval(vaultTimeout.seconds)
        return timeoutSeconds - elapsed
    }

    /// Calculates the tamper-resistant elapsed time since the user was last active, shared by
    /// `hasPassedSessionTimeout` and `timeUntilSessionTimeout`.
    ///
    /// - Parameter userId: The user ID to check.
    /// - Returns: The elapsed time in seconds since the user was last active, or `nil` if the
    ///   elapsed time can't be determined — missing last-active state, detected tampering (clock
    ///   manipulation or reboot), or a reboot-timing attack. Callers should fail closed and treat
    ///   `nil` as "already timed out".
    ///
    private func effectiveElapsedTime(userId: String) async throws -> TimeInterval? {
        let lastActiveMonotonic = try await userSessionStateService.getLastActiveMonotonicTime(userId: userId)
        let lastActiveTime = try await userSessionStateService.getLastActiveTime(userId: userId)

        // We need both times to calculate session timeout. If any of the times is not present
        // then treat it as the session has timed out.
        guard let lastActiveMonotonic, let lastActiveTime else {
            return nil
        }

        // Use monotonic time for tamper-resistant timeout checking
        let result = timeProvider.calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastActiveMonotonic,
            lastWallClockTime: lastActiveTime,
            divergenceThreshold: 5.0,
        )

        // Force timeout if tampering detected (reboot or clock manipulation)
        if result.tamperingDetected {
            return nil
        }

        // Check for the reboot-timing attack: an attacker who reboots the device and
        // waits until the monotonic clock matches the stored value bypasses the isReboot
        // flag. The boot epoch shifts dramatically across a reboot and catches this.
        // Guard on isReboot: a legitimate reboot is already caught above via tamperingDetected.
        let storedBootEpoch = try await userSessionStateService.getLastActiveBootEpoch(userId: userId)
        let currentBootEpoch = timeProvider.presentTime.timeIntervalSinceReferenceDate
            - timeProvider.monotonicTime
        // Boot epoch must always co-exist with lastActiveMonotonicTime — both are written
        // atomically in setLastActiveTime. A missing boot epoch after the guard above means
        // partial or manipulated state, so fail closed.
        guard let storedBootEpoch else {
            return nil
        }
        if !result.isReboot {
            let epochDrift = abs(currentBootEpoch - storedBootEpoch)
            if epochDrift > 5.0 {
                return nil
            }
        }

        return result.effectiveElapsed
    }
}
