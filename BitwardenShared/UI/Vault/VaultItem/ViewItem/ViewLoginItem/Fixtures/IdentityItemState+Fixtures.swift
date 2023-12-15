import BitwardenSdk
import Foundation

extension IdentityItemState {
    static func fixture(
        title: DefaultableType<TitleType> = .default,
        firstName: String = "",
        lastName: String = "",
        middleName: String = "",
        userName: String = "",
        company: String = "",
        socialSecurityNumber: String = "",
        passportNumber: String = "",
        licenseNumber: String = "",
        email: String = "",
        phone: String = "",
        address1: String = "",
        address2: String = "",
        address3: String = "",
        cityOrTown: String = "",
        state: String = "",
        postalCode: String = "",
        country: String = ""
    ) -> Self {
        .init(
            title: title,
            firstName: firstName,
            lastName: lastName,
            middleName: middleName,
            userName: userName,
            company: company,
            socialSecurityNumber: socialSecurityNumber,
            passportNumber: passportNumber,
            licenseNumber: licenseNumber,
            email: email,
            phone: phone,
            address1: address1,
            address2: address2,
            address3: address3,
            cityOrTown: cityOrTown,
            state: state,
            postalCode: postalCode,
            country: country
        )
    }
}
