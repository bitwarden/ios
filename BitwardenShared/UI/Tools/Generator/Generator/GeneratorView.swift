import SwiftUI

/// A view containing the generator used to generate new usernames and passwords.
///
struct GeneratorView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<GeneratorState, GeneratorAction, Void>

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
        .onAppear { store.send(.appeared) }
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
                    }
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
                .background(Asset.Colors.backgroundElevatedTertiary.swiftUIColor)
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
                Asset.Images.restart.swiftUIImage
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
        field: FormMenuField<GeneratorState, GeneratorState.UsernameState.UsernameGeneratorType>
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
