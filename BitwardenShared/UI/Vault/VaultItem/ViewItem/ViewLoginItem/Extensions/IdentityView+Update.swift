import BitwardenSdk // swiftlint:disable:this file_name

// MARK: - LoginView+Update

extension BitwardenSdk.IdentityView {
    /// initializes a new IdentityView with updated properties
    ///
    /// - Parameters:
    ///   - identityView: A `BitwardenSdk.IdentityView` to use as a base for the update.
    ///   - identityState: The `IdentityItemState` used to create or update the login view.
    ///
    init(identityView: BitwardenSdk.IdentityView?, identityState: IdentityItemState) {
        self.init(
            title: {
                guard case let .custom(value) = identityState.title else { return nil }
                return value.localizedName
            }(),
            firstName: identityState.firstName.nilIfEmpty,
            middleName: identityState.middleName.nilIfEmpty,
            lastName: identityState.lastName.nilIfEmpty,
            address1: identityState.address1.nilIfEmpty,
            address2: identityState.address2.nilIfEmpty,
            address3: identityState.address3.nilIfEmpty,
            city: identityState.cityOrTown.nilIfEmpty,
            state: identityState.state.nilIfEmpty,
            postalCode: identityState.postalCode.nilIfEmpty,
            country: identityState.country.nilIfEmpty,
            company: identityState.company.nilIfEmpty,
            email: identityState.email.nilIfEmpty,
            phone: identityState.phone.nilIfEmpty,
            ssn: identityState.identityView.ssn?.nilIfEmpty,
            username: identityState.userName.nilIfEmpty,
            passportNumber: identityState.passportNumber.nilIfEmpty,
            licenseNumber: identityState.licenseNumber.nilIfEmpty
        )
    }
}
