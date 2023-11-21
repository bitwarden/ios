import SwiftUI

/// A view containing the generator used to generate new usernames and passwords.
///
struct GeneratorView: View {
    // MARK: Properties

    /// The key path of the currently focused text field.
    @FocusState private var focusedFieldKeyPath: KeyPath<GeneratorState, String>?

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<GeneratorState, GeneratorAction, GeneratorEffect>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(store.state.formSections) { section in
                    sectionView(section)
                }
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(Localizations.generator)
        .task { await store.perform(.appeared) }
        .onChange(of: focusedFieldKeyPath) { newValue in
            store.send(.textFieldFocusChanged(keyPath: newValue))
        }
        .toast(store.binding(
            get: \.toast,
            send: GeneratorAction.toastShown
        ))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        store.send(.showPasswordHistory)
                    } label: {
                        Text(Localizations.passwordHistory)
                    }
                } label: {
                    Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
                        .resizable()
                        .frame(width: 19, height: 19)
                        .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                }
            }
        }
    }

    /// Returns a view for displaying a section of items in the form.
    ///
    /// - Parameter section: The data for displaying in the section.
    ///
    @ViewBuilder
    func sectionView(_ section: GeneratorState.FormSection<GeneratorState>) -> some View {
        if let title = section.title {
            Text(title.uppercased())
                .font(.styleGuide(.footnote))
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        }

        VStack(spacing: 12) {
            ForEach(section.fields) { field in
                switch field.fieldType {
                case let .generatedValue(generatedValueField):
                    generatedValueView(field: generatedValueField)
                case let .menuGeneratorType(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.generatorTypeChanged(newValue))
                    }
                case let .menuPasswordGeneratorType(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.passwordGeneratorTypeChanged(newValue))
                    }
                case let .menuUsernameForwardedEmailService(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.usernameForwardedEmailServiceChanged(newValue))
                    }
                case let .menuUsernameGeneratorType(menuField):
                    menuUsernameGeneratorTypeView(field: menuField)
                case let .slider(sliderField):
                    SliderFieldView(field: sliderField) { newValue in
                        store.send(.sliderValueChanged(field: sliderField, value: newValue))
                    }
                case let .stepper(stepperField):
                    StepperFieldView(field: stepperField) { newValue in
                        store.send(.stepperValueChanged(field: stepperField, value: newValue))
                    }
                case let .text(textField):
                    FormTextFieldView(field: textField) { newValue in
                        store.send(.textValueChanged(field: textField, value: newValue))
                    } isPasswordVisibleChangedAction: { newValue in
                        store.send(.textFieldIsPasswordVisibleChanged(field: textField, value: newValue))
                    }
                    .focused($focusedFieldKeyPath, equals: textField.keyPath)
                case let .toggle(toggleField):
                    ToggleFieldView(field: toggleField) { isOn in
                        store.send(.toggleValueChanged(field: toggleField, isOn: isOn))
                    }
                }
            }
        }
    }

    /// Returns a view for displaying a generated value (the generated password, username or email).
    ///
    /// - Parameter field: The data for displaying the generated value field.
    ///
    @ViewBuilder
    func generatedValueView(field: GeneratorState.GeneratedValueField<GeneratorState>) -> some View {
        HStack(spacing: 8) {
            Text(field.value)
                .font(.styleGuide(.bodyMonospaced))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                .cornerRadius(10)

            Button {
                store.send(.copyGeneratedValue)
            } label: {
                Asset.Images.copy.swiftUIImage
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.accessory)
            .accessibilityLabel(Localizations.copyPassword)

            Button {
                store.send(.refreshGeneratedValue)
            } label: {
                Asset.Images.restart2.swiftUIImage
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.accessory)
            .accessibilityLabel(Localizations.generatePassword)
        }
    }

    /// Returns a view for displaying a menu for selecting the username type
    ///
    /// - Parameter field: The data for displaying the menu field.
    ///
    func menuUsernameGeneratorTypeView(
        field: FormMenuField<GeneratorState, UsernameGeneratorType>
    ) -> some View {
        FormMenuFieldView(field: field) { newValue in
            store.send(.usernameGeneratorTypeChanged(newValue))
        } trailingContent: {
            Button {
                openURL(ExternalLinksConstants.generatorUsernameTypes)
            } label: {
                Asset.Images.questionRound.swiftUIImage
                    .resizable()
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.accessory)
            .accessibilityLabel(Localizations.learnMore)
        }
    }
}

// MARK: - Previews

struct GeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GeneratorView(store: Store(processor: StateProcessor(state: GeneratorState())))
        }
    }
}
