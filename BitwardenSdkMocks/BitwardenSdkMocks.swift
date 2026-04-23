// swiftlint:disable:this file_name

// Sourcery cannot annotate types defined in external modules like `BitwardenSdk`. To generate
// mocks for SDK types, we declare empty extensions here so Sourcery can see them. The
// `sourcery:file: AutoMockable` annotation below applies `AutoMockable` to every type in this
// file, eliminating the need to annotate each extension individually.
// sourcery:file: AutoMockable

import BitwardenSdk

extension ClientManagedTokens {}
