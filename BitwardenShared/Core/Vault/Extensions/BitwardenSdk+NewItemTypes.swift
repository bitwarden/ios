// swiftlint:disable:this file_name

import BitwardenSdk

// MARK: - NewItemTypesSdkBridge

/// Centralized SDK-availability gating for the PM-32009 new item types.
///
/// `BitwardenSdk` does not yet expose `BankAccount` / `BankAccountView` /
/// `CipherType.bankAccount` (and similarly for Driver's License and Passport once they land).
/// Until the SDK ships support, every app-layer site that needs to bridge one of the new
/// types across the SDK boundary should route through this namespace so that flipping
/// availability is a single-file change.
///
/// **Why centralize?** PR 1 (Bank Account) added ~6 `TODO: PM-32009 Blocked on SDK` sites.
/// PR 2 (Driver's License) and PR 3 (Passport) would multiply that to ~18 without a shim.
/// When the SDK lands with the new cases, `isBankAccountAvailable` (and siblings) flip
/// to `true` and the conditional branches below swap to real SDK conversions — the rest
/// of the codebase stays still.
///
/// - Note: All members are `static` and side-effect free. The bridge does not hold state.
///
enum NewItemTypesSdkBridge {
    // MARK: SDK Availability Flags

    /// Whether the current `BitwardenSdk` dependency exposes the Bank Account types
    /// (`BitwardenSdk.CipherType.bankAccount`, `BitwardenSdk.BankAccount`,
    /// `BitwardenSdk.BankAccountView`). Flip to `true` when the SDK ships support and
    /// replace the guarded fallbacks below with real SDK conversions.
    ///
    /// - SeeAlso: `TODO: PM-32009` markers elsewhere are intentionally kept next to the
    ///   call sites that will need source-level edits when the SDK lands — the flag
    ///   alone is not sufficient to enable the new type end-to-end.
    static let isBankAccountAvailable = false

    // MARK: Bank Account Bridging

    /// Returns the SDK `BitwardenSdk.CipherType` value corresponding to the app-layer
    /// `CipherType.bankAccount` case, or `nil` if the SDK does not yet expose a
    /// `.bankAccount` case.
    ///
    /// Callers must fail closed when this returns `nil` — do NOT coerce to any other
    /// SDK type (e.g., `.secureNote`) as that would cause silent data loss. See
    /// `BitwardenSdk+Vault.swift::BitwardenSdk.CipherType.init(_:)`.
    ///
    /// - Returns: The SDK enum case, or `nil` while the SDK is blocked on PM-32009.
    ///
    static func sdkCipherTypeForBankAccount() -> BitwardenSdk.CipherType? {
        // TODO: PM-32009 Blocked on SDK — return `.bankAccount` once BitwardenSdk ships
        // the case. Until then, return nil so callers fail closed.
        nil
    }

    /// Maps a `BitwardenSdk.CipherType` to the app-layer `CipherType.bankAccount` if
    /// applicable.
    ///
    /// - Parameter _: An SDK cipher type to test.
    /// - Returns: `.bankAccount` when the SDK type matches the (future) SDK `.bankAccount`
    ///   case, `nil` otherwise.
    ///
    static func appCipherTypeForBankAccount(_: BitwardenSdk.CipherType) -> CipherType? {
        // TODO: PM-32009 Blocked on SDK — when the SDK adds `.bankAccount`, switch on
        // the value and return `.bankAccount` only for that case.
        nil
    }

    /// Whether a `BitwardenSdk.CipherListViewType` represents a bank account list row.
    ///
    /// Used by vault-list group filters to avoid pulling in the SDK's associated-value
    /// enum pattern at call sites.
    ///
    /// - Parameter _: The SDK list view type to test.
    /// - Returns: `true` when the SDK list view type is the (future) `.bankAccount`,
    ///   `false` otherwise.
    ///
    static func isBankAccountListViewType(_: BitwardenSdk.CipherListViewType) -> Bool {
        // TODO: PM-32009 Blocked on SDK — switch on the SDK type once `.bankAccount`
        // exists and return `true` for that case only.
        false
    }
}
