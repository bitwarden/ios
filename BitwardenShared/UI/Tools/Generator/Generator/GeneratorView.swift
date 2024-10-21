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
                if store.state.isPolicyInEffect {
                    InfoContainer(Localizations.passwordGeneratorPolicyInEffect)
                        .accessibilityIdentifier("PasswordGeneratorPolicyInEffectLabel")
                }

                ForEach(store.state.formSections) { section in
                    sectionView(section)
                }
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBarTitleDisplayMode(store.state.presentationMode == .inPlace ? .inline : .large)
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
            ToolbarItem(placement: .topBarLeading) {
                if store.state.presentationMode.isDismissButtonVisible {
                    cancelToolbarButton {
                        store.send(.dismissPressed)
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if store.state.presentationMode.isSelectButtonVisible {
                    toolbarButton(Localizations.select) {
                        store.send(.selectButtonPressed)
                    }
                    .accessibilityIdentifier("SelectButton")
                }

                if store.state.presentationMode.isOptionsButtonVisible {
                    optionsToolbarMenu {
                        Button(Localizations.passwordHistory) {
                            store.send(.showPasswordHistory)
                        }
                    }
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
        // swiftlint:disable:previous function_body_length
        if let title = section.title {
            Text(title.uppercased())
                .styleGuide(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        }

        VStack(spacing: 12) {
            ForEach(section.fields) { field in
                switch field.fieldType {
                case let .emailWebsite(website):
                    emailWebsiteView(website: website)
                case let .generatedValue(generatedValueField):
                    generatedValueView(field: generatedValueField)
                case let .menuEmailType(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.emailTypeChanged(newValue))
                    }
                case let .menuGeneratorType(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.generatorTypeChanged(newValue))
                    }
                case let .menuPasswordGeneratorType(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.passwordGeneratorTypeChanged(newValue))
                    }.disabled(store.state.policyOptions?.overridePasswordType ?? false)
                case let .menuUsernameForwardedEmailService(menuField):
                    FormMenuFieldView(field: menuField) { newValue in
                        store.send(.usernameForwardedEmailServiceChanged(newValue))
                    }
                case let .menuUsernameGeneratorType(menuField):
                    menuUsernameGeneratorTypeView(field: menuField)
                case let .slider(sliderField):
                    SliderFieldView(field: sliderField) { isEditing in
                        store.send(.sliderEditingChanged(field: sliderField, isEditing: isEditing))
                    } onValueChanged: { newValue in
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

    /// Returns a view for displaying a static email website field.
    ///
    /// - Parameter website: The website to display in the field.
    ///
    @ViewBuilder
    func emailWebsiteView(website: String) -> some View {
        BitwardenField(title: Localizations.website) {
            Text(website)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        }
    }

    /// Returns a view for displaying a generated value (the generated password, username or email).
    ///
    /// - Parameter field: The data for displaying the generated value field.
    ///
    @ViewBuilder
    func generatedValueView(field: GeneratorState.GeneratedValueField<GeneratorState>) -> some View {
        BitwardenField {
            PasswordText(password: field.value, isPasswordVisible: true)
                .accessibilityIdentifier("GeneratedPasswordLabel")
        } accessoryContent: {
            Button {
                store.send(.copyGeneratedValue)
            } label: {
                Asset.Images.copy.swiftUIImage
                    .imageStyle(.accessoryIcon)
            }
            .buttonStyle(.accessory)
            .accessibilityIdentifier("CopyValueButton")
            .accessibilityLabel(Localizations.copyPassword)

            Button {
                store.send(.refreshGeneratedValue)
            } label: {
                Asset.Images.restart2.swiftUIImage
                    .imageStyle(.accessoryIcon)
            }
            .buttonStyle(.accessory)
            .accessibilityIdentifier("RegenerateValueButton")
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

#if DEBUG
#Preview {
    NavigationView {
        GeneratorView(store: Store(processor: StateProcessor(state: GeneratorState())))
    }
}
#endif
