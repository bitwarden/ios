import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    static let organizationAutoEnrollStatus = loadFromJsonBundle(resource: "OrganizationAutoEnrollStatus")
    static let organizationAutoEnrollStatusDisabled = loadFromJsonBundle(
        resource: "OrganizationAutoEnrollStatusDisabled",
    )
    static let organizationKeys = loadFromJsonBundle(resource: "OrganizationKeys")
    static let singleSignOnDomainsVerified = loadFromJsonBundle(resource: "SingleSignOnDomainsVerified")
    static let singleSignOnDomainsVerifiedEmptyData = loadFromJsonBundle(
        resource: "SingleSignOnDomainsVerifiedEmptyData",
    )
    static let singleSignOnDomainsVerifiedEmptyOrgId = loadFromJsonBundle(
        resource: "SingleSignOnDomainsVerifiedEmptyOrgId",
    )
    static let singleSignOnDomainsVerifiedNoData = loadFromJsonBundle(resource: "SingleSignOnDomainsVerifiedNoData")
    static let singleSignOnDomainsVerifiedNoOrgId = loadFromJsonBundle(resource: "SingleSignOnDomainsVerifiedNoOrgId")
    static let singleSignOnDomainsVerifiedMultiple = loadFromJsonBundle(
        resource: "SingleSignOnDomainsVerifiedMultiple",
    )
}

// swiftlint:enable missing_docs
