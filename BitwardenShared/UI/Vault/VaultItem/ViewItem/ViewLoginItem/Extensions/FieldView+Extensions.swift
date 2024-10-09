import BitwardenSdk // swiftlint:disable:this file_name

// MARK: - FieldView+Update

extension BitwardenSdk.FieldView {
    /// initializes a new LoginView with updated properties
    ///
    /// - Parameter customFieldState: The `CustomFieldState` used to create or update the field view.
    ///
    init(customFieldState: CustomFieldState) {
        self.init(
            name: customFieldState.name,
            value: customFieldState.value,
            type: BitwardenSdk.FieldType(fieldType: customFieldState.type),
            linkedId: customFieldState.linkedIdType?.rawValue
        )
    }
}
