// swiftlint:disable:this file_name

import BitwardenSdk

extension BitwardenSdk.CardListView {
    static func fixture(
        brand: String? = nil
    ) -> CardListView {
        .init(
            brand: brand
        )
    }
}
