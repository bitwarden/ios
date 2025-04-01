import TestHelpers

extension APITestData {
    static let organizationAutoEnrollStatus = loadFromJsonBundle(resource: "OrganizationAutoEnrollStatus")
    static let organizationAutoEnrollStatusDisabled = loadFromJsonBundle(
        resource: "OrganizationAutoEnrollStatusDisabled"
    )
    static let organizationKeys = loadFromJsonBundle(resource: "OrganizationKeys")
    static let singleSignOnDetails = loadFromJsonBundle(resource: "SingleSignOnDetails")
    static let singleSignOnDetailsNoOrgId = loadFromJsonBundle(resource: "SingleSignOnDetailsNoOrgId")
    static let singleSignOnDetailsNotAvailable = loadFromJsonBundle(resource: "SingleSignOnDetailsNotAvailable")
    static let singleSignOnDetailsNoVerifiedDate = loadFromJsonBundle(resource: "SingleSignOnDetailsNoVerifiedDate")
    static let singleSignOnDetailsOrgIdEmpty = loadFromJsonBundle(resource: "SingleSignOnDetailsOrgIdEmpty")
    static let singleSignOnDomainsVerified = loadFromJsonBundle(resource: "SingleSignOnDomainsVerified")
    static let singleSignOnDomainsVerifiedEmptyData = loadFromJsonBundle(
        resource: "SingleSignOnDomainsVerifiedEmptyData"
    )
    static let singleSignOnDomainsVerifiedEmptyOrgId = loadFromJsonBundle(
        resource: "SingleSignOnDomainsVerifiedEmptyOrgId"
    )
    static let singleSignOnDomainsVerifiedNoData = loadFromJsonBundle(resource: "SingleSignOnDomainsVerifiedNoData")
    static let singleSignOnDomainsVerifiedNoOrgId = loadFromJsonBundle(resource: "SingleSignOnDomainsVerifiedNoOrgId")
    static let singleSignOnDomainsVerifiedMultiple = loadFromJsonBundle(
        resource: "SingleSignOnDomainsVerifiedMultiple"
    )
}
