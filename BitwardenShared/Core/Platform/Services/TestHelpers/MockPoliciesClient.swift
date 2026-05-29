import BitwardenSdk
import Foundation

class MockPoliciesClient: PoliciesClientProtocol {
    // MARK: - filterByType

    var filterByTypeCallsCount = 0
    var filterByTypeCalled: Bool { filterByTypeCallsCount > 0 }
    // swiftlint:disable:next large_tuple
    var filterByTypeReceivedArguments: (
        policies: [PolicyView],
        organizationUserPolicyContexts: [OrganizationUserPolicyContext],
        policyType: PolicyType,
    )?
    var filterByTypeReturnValue: [PolicyView] = []
    var filterByTypeClosure: (([PolicyView], [OrganizationUserPolicyContext], PolicyType) -> [PolicyView])?

    func filterByType(
        policies: [PolicyView],
        organizationUserPolicyContexts: [OrganizationUserPolicyContext],
        policyType: PolicyType,
    ) -> [PolicyView] {
        filterByTypeCallsCount += 1
        filterByTypeReceivedArguments = (
            policies: policies,
            organizationUserPolicyContexts: organizationUserPolicyContexts,
            policyType: policyType,
        )
        if let closure = filterByTypeClosure {
            return closure(policies, organizationUserPolicyContexts, policyType)
        }
        return filterByTypeReturnValue
    }
}
