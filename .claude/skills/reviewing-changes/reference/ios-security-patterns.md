# Security Checklist — Bitwarden iOS

Bitwarden-specific security checks. These are mandatory — no exceptions.

## Zero-Knowledge Architecture

- [ ] No unencrypted vault data logged, persisted, or transmitted
- [ ] All encryption/decryption uses `BitwardenSdk` — no custom crypto implementations
- [ ] Cipher data flows only through SDK encryption/decryption methods

## Secrets Storage

- [ ] Encryption keys, auth tokens, biometric keys stored via `KeychainRepository`/`KeychainService`
- [ ] No sensitive credentials in `UserDefaults` or `CoreData`
- [ ] No hardcoded API keys, tokens, or credentials in code

## Error Handling

- [ ] Sensitive errors implement `NonLoggableError` protocol — not reported to crash analytics
- [ ] `ErrorReporter` does not receive unencrypted vault data in error context
- [ ] No `try!` force-throws in production code paths

## Input Validation

- [ ] All external/user input validated via `InputValidator` utilities
- [ ] No direct string interpolation of user input into sensitive operations

## Extension Memory Limits

- [ ] AutoFill/Action extensions: KDF memory usage checked for Argon2id > 64 MB (`maxArgon2IdMemoryBeforeExtensionCrashing`)
- [ ] Extension-facing code paths warn users when memory limits may be exceeded

## Security-Critical Constants

- [ ] Changes to KDF parameters, unlock limits, or token thresholds reference `Constants.swift`
- [ ] No magic numbers for security-sensitive values
