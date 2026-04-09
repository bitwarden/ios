import AuthenticationServices
import Testing

@testable import BitwardenShared

// MARK: - ASSettingsHelperProxyTests

/// Tests for ``DefaultASSettingsHelperProxy``.
///
/// ``DefaultASSettingsHelperProxy`` is a thin wrapper that defers directly to ``ASSettingsHelper``
/// OS APIs. The behaviour of those underlying APIs cannot be exercised in unit tests, so there
/// are no meaningful unit tests for this type beyond compile-time conformance verification.
struct ASSettingsHelperProxyTests {}
