import BitwardenResources
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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if store.state.availableGeneratorTypes.count > 1 {
                    BitwardenSegmentedControl(
                        isSelectionDisabled: { store.state.isGeneratorTypeDisabled($0) },
                        selection: store.binding(get: \.generatorType, send: GeneratorAction.generatorTypeChanged),
                        selections: store.state.availableGeneratorTypes
                    )
                    .guidedTourStep(.step1, perform: { frame in
                        let steps: [GuidedTourStep] = [.step1, .step2, .step3]
                        for step in steps {
                            store.send(
                                .guidedTourViewAction(.didRenderViewToSpotlight(
                                    frame: frame,
                                    step: step
                                ))
                            )
                        }
                    })
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
                }

                Divider()

                GuidedTourScrollView(
                    store: store.child(
                        state: \.guidedTourViewState,
                        mapAction: GeneratorAction.guidedTourViewAction,
                        mapEffect: nil
                    )
                ) {
                    VStack(alignment: .leading, spacing: 24) {
                        if store.state.isLearnGeneratorActionCardEligible,
                           store.state.presentationMode == .tab {
                            ActionCard(
                                title: Localizations.exploreTheGenerator,
                                message: Localizations.learnMoreAboutGeneratingSecureLoginCredentialsWithAGuidedTour,
                                actionButtonState: ActionCard.ButtonState(title: Localizations.getStarted) {
                                    await store.perform(.showLearnGeneratorGuidedTour)
                                },
                                dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                                    await store.perform(.dismissLearnGeneratorActionCard)
                                }
                            )
                        }

                        if store.state.isPolicyInEffect {
                            InfoContainer(Localizations.passwordGeneratorPolicyInEffect)
                                .accessibilityIdentifier("PasswordGeneratorPolicyInEffectLabel")
                        }

                        ForEach(store.state.formSections) { section in
                            sectionView(section, geometryProxy: geometry)
                        }
                    }
                    .padding(12)
                }
            }
            .coordinateSpace(name: "generatorView")
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .navigationBar(title: Localizations.generator, titleDisplayMode: .inline)
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

                largeNavigationTitleToolbarItem(
                    Localizations.generator,
                    hidden: store.state.presentationMode != .tab
                )

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
    }

    /// Returns a view for displaying a section of items in the form.
    ///
    /// - Parameters:
    ///   - section: The section of items to display.
    ///   - geometryProxy: The geometry proxy for the view.
    ///
    @ViewBuilder
    func sectionView(
        _ section: GeneratorState.FormSection<GeneratorState>,
        geometryProxy: GeometryProxy
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(section.groups) { group in
                if group.showInContentBlock {
                    ContentBlock(dividerLeadingPadding: 16) {
                        groupView(group)
                    }
                    .onFrameChanged(
                        id: GuidedTourStep.step4.id,
                        perform: { origin, size in
                            // The spotlight region for step 4 is quite large and may not fit on the
                            // screen even in portrait mode, potentially leaving some parts hidden.
                            // This calculation helps identify the visible portion of
                            // the spotlight region.
                            let globalFrame = CGRect(origin: origin, size: size)
                            var visibleFrame = globalFrame
                            let generatorViewFrame = geometryProxy.frame(in: .global)
                            if globalFrame.maxY > generatorViewFrame.maxY {
                                visibleFrame.size.height = generatorViewFrame.maxY
                                    - globalFrame.origin.y
                            }
                            store.send(
                                .guidedTourViewAction(.didRenderViewToSpotlight(
                                    frame: visibleFrame,
                                    step: .step4
                                ))
                            )
                        }
                    )
                } else {
                    groupView(group)
                }
            }
        }
    }

    /// Returns a view for displaying a group of items within a section of the form.
    ///
    /// - Parameter group: The group of items to display.
    ///
    func groupView(_ group: GeneratorState.FormSectionGroup<GeneratorState>) -> some View {
        ForEach(group.fields) { field in
            switch field.fieldType {
            case let .emailWebsite(website):
                emailWebsiteView(website: website)
            case let .generatedValue(generatedValueField):
                generatedValueView(field: generatedValueField)
                    .guidedTourStep(.step6) { frame in
                        store.send(
                            .guidedTourViewAction(
                                .didRenderViewToSpotlight(
                                    frame: frame,
                                    step: .step6
                                )
                            )
                        )
                    }
            case let .menuEmailType(menuField):
                FormMenuFieldView(field: menuField) { newValue in
                    store.send(.emailTypeChanged(newValue))
                }
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
                }.id(GuidedTourStep.step4.id)
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

    /// Returns a view for displaying a static email website field.
    ///
    /// - Parameter website: The website to display in the field.
    ///
    @ViewBuilder
    func emailWebsiteView(website: String) -> some View {
        BitwardenField(title: Localizations.website) {
            Text(website)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
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
            AccessoryButton(
                asset: Asset.Images.generate24,
                accessibilityLabel: Localizations.generatePassword,
                accessibilityIdentifier: "RegenerateValueButton"
            ) {
                store.send(.refreshGeneratedValue)
            }
            .guidedTourStep(.step5) { frame in
                store.send(
                    .guidedTourViewAction(.didRenderViewToSpotlight(
                        frame: frame.enlarged(by: 8),
                        step: .step5
                    ))
                )
            }
        }

        Button(Localizations.copy) {
            store.send(.copyGeneratedValue)
        }
        .buttonStyle(.primary())
        .accessibilityIdentifier("CopyValueButton")
        .accessibilityLabel(Localizations.copyPassword)
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
        } titleAccessoryContent: {
            Button {
                openURL(ExternalLinksConstants.generatorUsernameTypes)
            } label: {
                Asset.Images.questionCircle12.swiftUIImage
                    .scaledFrame(width: 12, height: 12)
            }
            .buttonStyle(.fieldLabelIcon)
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
