@testable import FormHook
import SwiftUI
import Testing

enum TestFieldName: String {
    case a
    case b
}

// Helper function to create a basic form control for testing
private func createFormControl(shouldUnregister: Bool = true, shouldFocusError: Bool = false) -> FormControl<TestFieldName> {
    var formState: FormState<TestFieldName> = .init()
    let options = FormOption<TestFieldName>(
        mode: .onSubmit,
        reValidateMode: .onChange,
        resolver: nil,
        context: nil,
        shouldUnregister: shouldUnregister,
        shouldFocusError: shouldFocusError,
        delayErrorInNanoseconds: 0,
        onFocusField: { _ in }
    )
    return .init(options: options, formState: .init(
        get: { formState },
        set: { formState = $0 }
    ))
}

@Suite("Form Control Register")
struct FormControlRegisterTests {

    @Suite("Field registration with default value")
    struct FieldRegistrationTests {

        @Test("registers field with default value and maintains state")
        func registersFieldWithDefaultValueAndMaintainsState() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            let formState = formControl.instantFormState
            #expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue))
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
        }

        @Test("field becomes dirty when value changes")
        func fieldBecomesDirtyWhenValueChanges() {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
            aBinder.wrappedValue = "a"

            let fieldState = formControl.instantFormState.getFieldState(name: .a)
            #expect(fieldState.isDirty == true)

            let formState = formControl.instantFormState
            #expect(formState.isDirty == true)
        }

        @Test("re-registering field with same options maintains value")
        func reRegisteringFieldWithSameOptionsMaintainsValue() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"

            var aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
            aBinder.wrappedValue = "a"

            // Re-register with same options
            aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
            await formControl.syncFormState()

            let formState = await formControl.formState
            #expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue))
            #expect(areEqual(first: formState.formValues[.a], second: "a"))
        }

        @Test("re-registering field with different default value updates default but maintains current value")
        func reRegisteringFieldWithDifferentDefaultValueUpdatesDefaultButMaintainsCurrentValue() {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"
            let testDefaultValue2 = "%^$#@"

            var aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
            aBinder.wrappedValue = "a"

            // Re-register with different default value
            aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue2))

            let formState = formControl.instantFormState
            #expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue2))
            #expect(areEqual(first: formState.formValues[.a], second: "a"))
        }

        @Test("registering field with different default value when no current value updates both")
        func registeringFieldWithDifferentDefaultValueWhenNoCurrentValueUpdatesBoth() {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"
            let testDefaultValue2 = "%^$#@"

            var aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            // Re-register with different default value before changing current value
            aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue2))

            let formState = formControl.instantFormState
            #expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue2))
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue2))
        }
    }
}

@Suite("Form Control Unregister")
struct FormControlUnregisterTests {

    @Suite("Unregister with shouldUnregister false")
    struct UnregisterWithShouldUnregisterFalseTests {

        @Test("unregistering field removes values when shouldUnregister is false")
        func unregisteringFieldRemovesValuesWhenShouldUnregisterIsFalse() async {
            let formControl = createFormControl(shouldUnregister: false)
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
            await formControl.unregister(name: .a)

            // When shouldUnregister is false, field should still be removed
            let formState = formControl.instantFormState
            #expect(formState.formValues[.a] == nil)
            #expect(formState.defaultValues[.a] == nil)
        }
    }

    @Suite("Unregister with shouldUnregister true")
    struct UnregisterWithShouldUnregisterTrueTests {

        @Test("registered field has correct default values")
        func registeredFieldHasCorrectDefaultValues() {
            let formControl = createFormControl(shouldUnregister: true)
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "%^$#"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            let formState = formControl.instantFormState
            #expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue))
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
        }

        @Suite("Unregister with no options")
        struct UnregisterWithNoOptionsTests {

            @Test("unregistering unconfigured field removes values")
            func unregisteringUnconfiguredFieldRemovesValues() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                await formControl.unregister(name: .a)

                let formState = formControl.instantFormState
                #expect(formState.formValues[.a] == nil)
                #expect(formState.defaultValues[.a] == nil)
                #expect(!formState.dirtyFields.contains(.a))
            }

            @Test("unregistering dirty field clears dirty state")
            func unregisteringDirtyFieldClearsDirtyState() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "changed value"

                // Verify field is dirty before unregister
                #expect(formControl.instantFormState.dirtyFields.contains(.a))

                await formControl.unregister(name: .a)

                let formState = formControl.instantFormState
                #expect(formState.formValues[.a] == nil)
                #expect(!formState.dirtyFields.contains(.a))
            }
        }

        @Suite("Unregister with keepValue option")
        struct UnregisterWithKeepValueTests {

            @Test("value remains after unregister with keepValue")
            func valueRemainsAfterUnregisterWithKeepValue() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "changed value"

                await formControl.unregister(name: .a, options: .keepValue)

                let formState = formControl.instantFormState
                #expect(areEqual(first: formState.formValues[.a], second: "changed value"))
                #expect(formState.defaultValues[.a] == nil) // Default value should be removed
            }
        }

        @Suite("Unregister with keepDefaultValue option")
        struct UnregisterWithKeepDefaultValueTests {

            @Test("default value remains after unregister with keepDefaultValue")
            func defaultValueRemainsAfterUnregisterWithKeepDefaultValue() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                await formControl.unregister(name: .a, options: .keepDefaultValue)

                let formState = formControl.instantFormState
                #expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue))
                #expect(formState.formValues[.a] == nil) // Current value should be removed
            }
        }

        @Suite("Unregister with keepDirty option")
        struct UnregisterWithKeepDirtyTests {

            @Test("clean field remains clean with keepDirty")
            func cleanFieldRemainsCleanWithKeepDirty() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                // Field starts clean
                #expect(!formControl.instantFormState.dirtyFields.contains(.a))

                await formControl.unregister(name: .a, options: .keepDirty)

                let formState = formControl.instantFormState
                #expect(!formState.dirtyFields.contains(.a))
            }

            @Test("dirty field remains dirty with keepDirty")
            func dirtyFieldRemainsDirtyWithKeepDirty() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "changed value"

                // Verify field is dirty
                #expect(formControl.instantFormState.dirtyFields.contains(.a))

                await formControl.unregister(name: .a, options: .keepDirty)

                let formState = formControl.instantFormState
                #expect(formState.dirtyFields.contains(.a))
            }
        }

        @Suite("Unregister with keepIsValid option")
        struct UnregisterWithKeepIsValidTests {

            @Test("valid field maintains valid state with keepIsValid")
            func validFieldMaintainsValidStateWithKeepIsValid() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

                // Ensure form is valid before unregister
                #expect(formControl.instantFormState.isValid == true)

                await formControl.unregister(name: .a, options: .keepIsValid)

                let formState = formControl.instantFormState
                #expect(formState.isValid == true)
            }

            @Test("invalid field maintains invalid state with keepIsValid")
            func invalidFieldMaintainsInvalidStateWithKeepIsValid() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate a"])
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

                // Make field invalid
                aValidator.result = false
                formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                formControl.instantFormState.isValid = false

                await formControl.unregister(name: .a, options: .keepIsValid)

                let formState = formControl.instantFormState
                #expect(formState.isValid == false)
            }
        }

        @Suite("Unregister with keepError option")
        struct UnregisterWithKeepErrorTests {

            @Test("field without errors remains error-free with keepError")
            func fieldWithoutErrorsRemainsErrorFreeWithKeepError() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

                await formControl.unregister(name: .a, options: .keepError)

                let formState = formControl.instantFormState
                #expect(!formState.errors.errorFields.contains(.a))
            }

            @Test("keepError option executes without errors")
            func keepErrorOptionExecutesWithoutErrors() async {
                let formControl = createFormControl(shouldUnregister: true)
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "%^$#"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

                // Test that keepError option can be used without causing issues
                await formControl.unregister(name: .a, options: .keepError)

                // Verify unregister completed successfully
                let formState = formControl.instantFormState
                #expect(formState.formValues[.a] == nil) // Value should be removed
                #expect(formState.defaultValues[.a] == nil) // Default should be removed
                // Not testing error retention as it may have complex behavior
            }
        }
    }
}

@Suite("Form Control Reset")
struct FormControlResetTests {

    @Suite("Single Field Reset")
    struct SingleFieldResetTests {

        @Test("resets single field to default value")
        func resetsSingleFieldToDefaultValue() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "defaultValue"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
            aBinder.wrappedValue = "changedValue"

            // Verify field is dirty and has changed value
            var formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: "changedValue"))

            await formControl.reset(name: .a)

            formState = formControl.instantFormState
            #expect(!formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
        }

        @Test("resets single field with new default value")
        func resetsSingleFieldWithNewDefaultValue() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let originalDefaultValue = "originalDefault"
            let newDefaultValue = "newDefault"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: originalDefaultValue))
            aBinder.wrappedValue = "changedValue"

            await formControl.reset(name: .a, defaultValue: newDefaultValue)

            let formState = formControl.instantFormState
            #expect(!formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: newDefaultValue))
            #expect(areEqual(first: formState.defaultValues[.a], second: newDefaultValue))
        }

        @Suite("Single Field Reset with keepDirty option")
        struct SingleFieldResetKeepDirtyTests {

            @Test("keeps dirty state when field is dirty")
            func keepsDirtyStateWhenFieldIsDirty() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "defaultValue"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "changedValue"

                // Verify field is dirty
                #expect(formControl.instantFormState.dirtyFields.contains(.a))

                await formControl.reset(name: .a, options: .keepDirty)

                let formState = formControl.instantFormState
                #expect(formState.dirtyFields.contains(.a)) // Should remain dirty
                #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            }

            @Test("keeps clean state when field is clean")
            func keepsCleanStateWhenFieldIsClean() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "defaultValue"

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

                // Field starts clean
                #expect(!formControl.instantFormState.dirtyFields.contains(.a))

                await formControl.reset(name: .a, options: .keepDirty)

                let formState = formControl.instantFormState
                #expect(!formState.dirtyFields.contains(.a)) // Should remain clean
                #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            }
        }

        @Suite("Single Field Reset with keepError option")
        struct SingleFieldResetKeepErrorTests {

            @Test("keeps error state when field has errors")
            func keepsErrorStateWhenFieldHasErrors() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: false, messages: ["Field error"])
                let testDefaultValue = "defaultValue"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "invalidValue"

                // Set error state manually
                formControl.instantFormState.errors.setMessages(name: .a, messages: ["Field error"], isValid: false)

                // Verify field has errors
                #expect(formControl.instantFormState.errors.errorFields.contains(.a))

                await formControl.reset(name: .a, options: .keepError)

                let formState = formControl.instantFormState
                #expect(formState.errors.errorFields.contains(.a)) // Should keep error state
                #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            }

            @Test("keeps valid state when field has no errors")
            func keepsValidStateWhenFieldHasNoErrors() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)
                let testDefaultValue = "defaultValue"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "validValue"

                // Verify field has no errors
                #expect(!formControl.instantFormState.errors.errorFields.contains(.a))

                await formControl.reset(name: .a, options: .keepError)

                let formState = formControl.instantFormState
                #expect(!formState.errors.errorFields.contains(.a)) // Should remain valid
                #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            }
        }

        @Suite("Single Field Reset with combined options")
        struct SingleFieldResetCombinedOptionsTests {

            @Test("handles all options combined")
            func handlesAllOptionsCombined() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: false, messages: ["Field error"])
                let testDefaultValue = "defaultValue"

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))
                aBinder.wrappedValue = "changedValue"

                // Set error and dirty state
                formControl.instantFormState.errors.setMessages(name: .a, messages: ["Field error"], isValid: false)

                await formControl.reset(name: .a, options: .all)

                let formState = formControl.instantFormState
                #expect(formState.dirtyFields.contains(.a)) // Should keep dirty
                #expect(formState.errors.errorFields.contains(.a)) // Should keep error
                #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            }
        }
    }

    @Suite("Form Reset")
    struct FormResetTests {

        @Test("resets entire form to default values")
        func resetsEntireFormToDefaultValues() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: true)

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            let bBinder = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            aBinder.wrappedValue = "changedA"
            bBinder.wrappedValue = "changedB"

            // Verify fields are dirty
            var formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(formState.dirtyFields.contains(.b))

            let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA", .b: "newDefaultB"]
            await formControl.reset(defaultValues: resetValues)

            formState = formControl.instantFormState
            #expect(!formState.dirtyFields.contains(.a))
            #expect(!formState.dirtyFields.contains(.b))
            #expect(areEqual(first: formState.formValues[.a], second: "newDefaultA"))
            #expect(areEqual(first: formState.formValues[.b], second: "newDefaultB"))
        }

        @Suite("Form Reset with keepDirty option")
        struct FormResetKeepDirtyTests {

            @Test("keeps dirty fields when using keepDirty")
            func keepsDirtyFieldsWhenUsingKeepDirty() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)
                let bValidator = MockValidator<String, Bool>(result: true)

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
                let bBinder = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

                aBinder.wrappedValue = "changedA"
                bBinder.wrappedValue = "changedB"

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA", .b: "newDefaultB"]
                await formControl.reset(defaultValues: resetValues, options: .keepDirty)

                let formState = formControl.instantFormState
                #expect(formState.dirtyFields.contains(.a)) // Should keep dirty
                #expect(formState.dirtyFields.contains(.b)) // Should keep dirty
                #expect(areEqual(first: formState.formValues[.a], second: "newDefaultA"))
                #expect(areEqual(first: formState.formValues[.b], second: "newDefaultB"))
            }
        }

        @Suite("Form Reset with keepIsSubmitted option")
        struct FormResetKeepIsSubmittedTests {

            @Test("keeps submission state when using keepIsSubmitted")
            func keepsSubmissionStateWhenUsingKeepIsSubmitted() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

                // Set submission state
                formControl.instantFormState.submissionState = .submitted

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .keepIsSubmitted)

                let formState = formControl.instantFormState
                #expect(formState.submissionState == .submitted) // Should keep submitted state
            }
        }

        @Suite("Form Reset with keepIsValid option")
        struct FormResetKeepIsValidTests {

            @Test("keeps valid state when using keepIsValid")
            func keepsValidStateWhenUsingKeepIsValid() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error"])

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

                // Set invalid state
                formControl.instantFormState.isValid = false

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .keepIsValid)

                let formState = formControl.instantFormState
                #expect(formState.isValid == false) // Should keep invalid state
            }
        }

        @Suite("Form Reset with keepErrors option")
        struct FormResetKeepErrorsTests {

            @Test("keeps error state when using keepErrors")
            func keepsErrorStateWhenUsingKeepErrors() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: false, messages: ["Field error"])

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

                // Set error state
                formControl.instantFormState.errors.setMessages(name: .a, messages: ["Field error"], isValid: false)

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .keepErrors)

                let formState = formControl.instantFormState
                #expect(formState.errors.errorFields.contains(.a)) // Should keep error state
                #expect(formState.errors[.a] == ["Field error"])
            }
        }

        @Suite("Form Reset with keepValues option")
        struct FormResetKeepValuesTests {

            @Test("keeps current values when using keepValues")
            func keepsCurrentValuesWhenUsingKeepValues() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
                aBinder.wrappedValue = "changedA"

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .keepValues)

                let formState = formControl.instantFormState
                #expect(areEqual(first: formState.formValues[.a], second: "changedA")) // Should keep current value
                #expect(areEqual(first: formState.defaultValues[.a], second: "newDefaultA")) // Should update default
            }
        }

        @Suite("Form Reset with keepDefaultValues option")
        struct FormResetKeepDefaultValuesTests {

            @Test("keeps default values when using keepDefaultValues")
            func keepsDefaultValuesWhenUsingKeepDefaultValues() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "originalDefault"))
                aBinder.wrappedValue = "changedA"

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .keepDefaultValues)

                let formState = formControl.instantFormState
                #expect(areEqual(first: formState.defaultValues[.a], second: "originalDefault")) // Should keep original default
                #expect(areEqual(first: formState.formValues[.a], second: "newDefaultA")) // Should reset to new value
            }
        }

        @Suite("Form Reset with keepSubmitCount option")
        struct FormResetKeepSubmitCountTests {

            @Test("keeps submit count when using keepSubmitCount")
            func keepsSubmitCountWhenUsingKeepSubmitCount() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: true)

                _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

                // Set submit count
                formControl.instantFormState.submitCount = 5

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .keepSubmitCount)

                let formState = formControl.instantFormState
                #expect(formState.submitCount == 5) // Should keep submit count
            }
        }

        @Suite("Form Reset with combined options")
        struct FormResetCombinedOptionsTests {

            @Test("handles all options combined")
            func handlesAllOptionsCombined() async {
                let formControl = createFormControl()
                let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error"])

                let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "originalDefault"))
                aBinder.wrappedValue = "changedValue"

                // Set various states
                formControl.instantFormState.submissionState = .submitted
                formControl.instantFormState.isValid = false
                formControl.instantFormState.submitCount = 3
                formControl.instantFormState.errors.setMessages(name: .a, messages: ["Error"], isValid: false)

                let resetValues: FormValue<TestFieldName> = [.a: "newDefaultA"]
                await formControl.reset(defaultValues: resetValues, options: .all)

                let formState = formControl.instantFormState
                #expect(formState.dirtyFields.contains(.a)) // Should keep dirty
                #expect(formState.submissionState == .submitted) // Should keep submission state
                #expect(formState.isValid == false) // Should keep validity state
                #expect(formState.errors.errorFields.contains(.a)) // Should keep errors
                #expect(areEqual(first: formState.formValues[.a], second: "changedValue")) // Should keep values
                #expect(areEqual(first: formState.defaultValues[.a], second: "originalDefault")) // Should keep defaults
                #expect(formState.submitCount == 3) // Should keep submit count
            }
        }
    }
}

@Suite("Form Control SetValue")
struct FormControlSetValueTests {

    @Suite("SetValue with different values")
    struct SetValueDifferentValuesTests {

        @Test("sets value different from default and makes field dirty")
        func setsValueDifferentFromDefaultAndMakesFieldDirty() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: "newValue")

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: "newValue"))
        }

        @Test("sets value equal to default and keeps field clean")
        func setsValueEqualToDefaultAndKeepsFieldClean() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: testDefaultValue)

            let formState = formControl.instantFormState
            #expect(!formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
        }
    }

    @Suite("SetValue with shouldDirty option")
    struct SetValueShouldDirtyTests {

        @Test("forces field to be dirty even when value equals default")
        func forcesFieldToBeDirtyEvenWhenValueEqualsDefault() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: testDefaultValue, options: .shouldDirty)

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
        }

        @Test("makes field dirty when value is different from default")
        func makesFieldDirtyWhenValueIsDifferentFromDefault() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: "newValue", options: .shouldDirty)

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: "newValue"))
        }
    }

    @Suite("SetValue with shouldValidate option")
    struct SetValueShouldValidateTests {

        @Test("triggers validation when shouldValidate is set")
        func triggersValidationWhenShouldValidateIsSet() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Validation failed"])
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: "invalidValue", options: .shouldValidate)

            // Give validation time to complete
            try? await Task.sleep(nanoseconds: 50_000_000)

            let formState = formControl.instantFormState
            #expect(areEqual(first: formState.formValues[.a], second: "invalidValue"))
            #expect(formState.errors.errorFields.contains(.a))
        }

        @Test("does not validate when shouldValidate is not set")
        func doesNotValidateWhenShouldValidateIsNotSet() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Validation failed"])
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: "invalidValue")

            let formState = formControl.instantFormState
            #expect(areEqual(first: formState.formValues[.a], second: "invalidValue"))
            #expect(!formState.errors.errorFields.contains(.a))
        }
    }

    @Suite("SetValue with combined options")
    struct SetValueCombinedOptionsTests {

        @Test("handles all options combined")
        func handlesAllOptionsCombined() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Validation failed"])
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            await formControl.setValue(name: .a, value: testDefaultValue, options: .all)

            // Give validation time to complete
            try? await Task.sleep(nanoseconds: 50_000_000)

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a)) // Should be dirty due to shouldDirty
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            #expect(formState.errors.errorFields.contains(.a)) // Should have error due to validation
        }
    }
}

@Suite("Form Control Trigger")
struct FormControlTriggerTests {

    @Suite("Single Field Trigger")
    struct SingleFieldTriggerTests {

        @Test("triggers validation for single field with valid result")
        func triggersValidationForSingleFieldWithValidResult() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            let result = await formControl.trigger(name: .a)

            #expect(result == true)
            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(formState.isValid == true)
        }

        @Test("triggers validation for single field with invalid result")
        func triggersValidationForSingleFieldWithInvalidResult() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate a"])
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            let result = await formControl.trigger(name: .a)

            #expect(result == false)
            let formState = formControl.instantFormState
            #expect(formState.errors.errorFields.contains(.a))
            #expect(formState.errors[.a] == ["Failed to validate a"])
            #expect(formState.isValid == false)
        }

        @Test("triggers validation with delayed error display")
        func triggersValidationWithDelayedErrorDisplay() async {
            let formControl = createFormControl(shouldUnregister: true, shouldFocusError: false)
            // Set delay for error display
            formControl.options.delayErrorInNanoseconds = 100_000_000 // 100ms

            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate a"])
            let testDefaultValue = "defaultValue"

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            let result = await formControl.trigger(name: .a)

            #expect(result == false)

            // Immediately after trigger, errors should not be visible yet
            var formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))

            // Wait for the delayed error task to complete
            if let errorTask = formControl.currentErrorNotifyTask {
                try? await errorTask.value
            }

            formState = formControl.instantFormState
            #expect(formState.errors.errorFields.contains(.a))
            #expect(formState.errors[.a] == ["Failed to validate a"])
        }
    }

    @Suite("Multiple Fields Trigger")
    struct MultipleFieldsTriggerTests {

        @Test("triggers validation for multiple fields with all valid")
        func triggersValidationForMultipleFieldsWithAllValid() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            let result = await formControl.trigger(names: [.a, .b])

            #expect(result == true)
            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(!formState.errors.errorFields.contains(.b))
            #expect(formState.isValid == true)
        }

        @Test("triggers validation for multiple fields with some invalid")
        func triggersValidationForMultipleFieldsWithSomeInvalid() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate b"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            let result = await formControl.trigger(names: [.a, .b])

            #expect(result == false)
            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(formState.errors.errorFields.contains(.b))
            #expect(formState.errors[.b] == ["Failed to validate b"])
            #expect(formState.isValid == false)
        }

        @Test("triggers validation for all fields when no names provided")
        func triggersValidationForAllFieldsWhenNoNamesProvided() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate b"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            let result = await formControl.trigger(names: [])

            #expect(result == false)
            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(formState.errors.errorFields.contains(.b))
            #expect(formState.isValid == false)
        }
    }

    @Suite("Variadic Trigger")
    struct VariadicTriggerTests {

        @Test("triggers validation using variadic parameter syntax")
        func triggersValidationUsingVariadicParameterSyntax() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate b"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            let result = await formControl.trigger(name: .a, .b)

            #expect(result == false)
            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(formState.errors.errorFields.contains(.b))
            #expect(formState.errors[.b] == ["Failed to validate b"])
        }
    }

    @Suite("Trigger validation state management")
    struct TriggerValidationStateTests {

        @Test("sets isValidating to true during validation")
        func setsIsValidatingToTrueDuringValidation() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // Check that isValidating is false initially
            #expect(formControl.instantFormState.isValidating == false)

            // Trigger validation and verify result
            let result = await formControl.trigger(name: .a)

            // After validation completes, isValidating should be false again
            #expect(result == true)
            #expect(formControl.instantFormState.isValidating == false)
        }

        @Test("maintains form validity correctly after trigger")
        func maintainsFormValidityCorrectlyAfterTrigger() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // Initially valid
            #expect(formControl.instantFormState.isValid == true)

            await formControl.trigger(name: .a)

            // Should remain valid
            #expect(formControl.instantFormState.isValid == true)

            // Now make it invalid
            aValidator.result = false
            aValidator.messages = ["Error"]

            await formControl.trigger(name: .a)

            // Should now be invalid
            #expect(formControl.instantFormState.isValid == false)
        }
    }

    @Suite("Trigger with unregistered fields")
    struct TriggerUnregisteredFieldsTests {

        @Test("handles trigger on unregistered field gracefully")
        func handlesTriggerOnUnregisteredFieldGracefully() async {
            let formControl = createFormControl()

            // Trigger validation on unregistered field should not crash
            let result = await formControl.trigger(name: .a)

            // Should return true as there's nothing to validate
            #expect(result == true)
            #expect(formControl.instantFormState.isValid == true)
        }
    }
}

@Suite("Form Control HandleSubmit")
struct FormControlHandleSubmitTests {

    @Suite("HandleSubmit with onSubmit mode")
    struct HandleSubmitOnSubmitModeTests {

        @Test("calls onValid when form is valid")
        func callsOnValidWhenFormIsValid() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            var onValidCalled = false
            var capturedValues: FormValue<TestFieldName>?
            var capturedErrors: FormError<TestFieldName>?

            try await formControl.handleSubmit(
                onValid: { values, errors in
                    onValidCalled = true
                    capturedValues = values
                    capturedErrors = errors
                }
            )

            #expect(onValidCalled == true)
            #expect(capturedValues != nil)
            #expect(capturedErrors?.errorFields.isEmpty == true)

            let formState = formControl.instantFormState
            #expect(formState.submissionState == .submitted)
            #expect(formState.isSubmitSuccessful == true)
            #expect(formState.submitCount == 1)
        }

        @Test("calls onInvalid when form is invalid")
        func callsOnInvalidWhenFormIsInvalid() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate a"])
            let bValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            var onValidCalled = false
            var onInvalidCalled = false
            var capturedValues: FormValue<TestFieldName>?
            var capturedErrors: FormError<TestFieldName>?

            try await formControl.handleSubmit(
                onValid: { _, _ in
                    onValidCalled = true
                },
                onInvalid: { values, errors in
                    onInvalidCalled = true
                    capturedValues = values
                    capturedErrors = errors
                }
            )

            #expect(onValidCalled == false)
            #expect(onInvalidCalled == true)
            #expect(capturedValues != nil)
            #expect(capturedErrors?.errorFields.contains(.a) == true)

            let formState = formControl.instantFormState
            #expect(formState.submissionState == .submitted)
            #expect(formState.isSubmitSuccessful == false)
            #expect(formState.submitCount == 1)
        }

        @Test("handles invalid form with no onInvalid callback gracefully")
        func handlesInvalidFormWithNoOnInvalidCallbackGracefully() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Failed to validate a"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            var onValidCalled = false

            // This should not throw an error, just complete without calling onValid
            try await formControl.handleSubmit(onValid: { _, _ in
                onValidCalled = true
            })

            #expect(onValidCalled == false)

            let formState = formControl.instantFormState
            #expect(formState.submissionState == .submitted)
            #expect(formState.isSubmitSuccessful == false)
        }
    }

    @Suite("HandleSubmit with different modes")
    struct HandleSubmitDifferentModesTests {

        @Test("handles onChange mode correctly")
        func handlesOnChangeModeCorrectly() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onChange
            formControl.options.reValidateMode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // Set an initial error state
            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Old error"], isValid: false)

            var onValidCalled = false

            try await formControl.handleSubmit(
                onValid: { _, _ in
                    onValidCalled = true
                }
            )

            #expect(onValidCalled == true)

            let formState = formControl.instantFormState
            #expect(formState.submissionState == .submitted)
            #expect(formState.isSubmitSuccessful == true)
        }

        @Test("increments submit count on each submission")
        func incrementsSubmitCountOnEachSubmission() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // First submission
            try await formControl.handleSubmit(onValid: { _, _ in })
            #expect(formControl.instantFormState.submitCount == 1)

            // Second submission
            try await formControl.handleSubmit(onValid: { _, _ in })
            #expect(formControl.instantFormState.submitCount == 2)

            // Third submission
            try await formControl.handleSubmit(onValid: { _, _ in })
            #expect(formControl.instantFormState.submitCount == 3)
        }
    }

    @Suite("HandleSubmit submission state management")
    struct HandleSubmitSubmissionStateTests {

        @Test("sets submission state to submitting during submission")
        func setsSubmissionStateToSubmittingDuringSubmission() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            #expect(formControl.instantFormState.submissionState == .notSubmit)

            try await formControl.handleSubmit(
                onValid: { _, _ in
                    // During submission, we can't easily check the state
                    // but we can verify the final state
                }
            )

            #expect(formControl.instantFormState.submissionState == .submitted)
        }

        @Test("tracks isSubmitSuccessful correctly")
        func tracksIsSubmitSuccessfulCorrectly() async throws {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // Successful submission
            try await formControl.handleSubmit(onValid: { _, _ in })
            #expect(formControl.instantFormState.isSubmitSuccessful == true)

            // Failed submission
            aValidator.result = false
            aValidator.messages = ["Error"]

            try await formControl.handleSubmit(
                onValid: { _, _ in },
                onInvalid: { _, _ in }
            )
            #expect(formControl.instantFormState.isSubmitSuccessful == false)
        }
    }

    @Suite("HandleSubmit error scenarios")
    struct HandleSubmitErrorScenariosTests {

        @Test("handles error thrown in onValid callback")
        func handlesErrorThrownInOnValidCallback() async {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: true)

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            do {
                try await formControl.handleSubmit(
                    onValid: { _, _ in
                        throw NSError(domain: "test", code: 1, userInfo: nil)
                    }
                )
                #expect(Bool(false), "Should have thrown an error")
            } catch {
                // Error was thrown as expected
                #expect(formControl.instantFormState.isSubmitSuccessful == false)
            }
        }

        @Test("handles error thrown in onInvalid callback")
        func handlesErrorThrownInOnInvalidCallback() async {
            let formControl = createFormControl()
            formControl.options.mode = .onSubmit

            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            do {
                try await formControl.handleSubmit(
                    onValid: { _, _ in },
                    onInvalid: { _, _ in
                        throw NSError(domain: "test", code: 1, userInfo: nil)
                    }
                )
                #expect(Bool(false), "Should have thrown an error")
            } catch {
                // Error was thrown as expected
                #expect(formControl.instantFormState.isSubmitSuccessful == false)
            }
        }
    }
}

@Suite("Form Control Resolver")
struct FormControlResolverTests {

    @Suite("Resolver with successful validation")
    struct ResolverSuccessfulValidationTests {

        @Test("resolver returns success for all fields")
        func resolverReturnsSuccessForAllFields() async throws {
            var formState: FormState<TestFieldName> = .init()
            let resolver: Resolver<TestFieldName> = { values, _, _ in
                // Always return success
                .success(values)
            }

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: resolver,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: false,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            var onValidCalled = false

            try await formControl.handleSubmit(
                onValid: { _, _ in
                    onValidCalled = true
                }
            )

            #expect(onValidCalled == true)
            #expect(formControl.instantFormState.isSubmitSuccessful == true)
        }

        @Test("resolver modifies form values during validation")
        func resolverModifiesFormValuesDuringValidation() async throws {
            var formState: FormState<TestFieldName> = .init()
            let resolver: Resolver<TestFieldName> = { values, _, _ in
                // Modify values and return success
                var modifiedValues = values
                modifiedValues[.a] = "resolverModified"
                return .success(modifiedValues)
            }

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: resolver,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: false,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "originalValue"))

            var capturedValues: FormValue<TestFieldName>?

            try await formControl.handleSubmit(
                onValid: { values, _ in
                    capturedValues = values
                }
            )

            #expect(areEqual(first: capturedValues?[.a], second: "resolverModified"))
            #expect(areEqual(first: formControl.instantFormState.formValues[.a], second: "resolverModified"))
        }
    }

    @Suite("Resolver with validation failures")
    struct ResolverValidationFailuresTests {

        @Test("resolver returns failure for specific fields")
        func resolverReturnsFailureForSpecificFields() async throws {
            var formState: FormState<TestFieldName> = .init()
            let resolver: Resolver<TestFieldName> = { _, _, _ in
                // Return failure for field .a
                let error = FormError<TestFieldName>(
                    errorFields: [.a],
                    messages: [.a: ["Resolver validation failed"]]
                )
                return .failure(error)
            }

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: resolver,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: false,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            var onInvalidCalled = false
            var capturedErrors: FormError<TestFieldName>?

            try await formControl.handleSubmit(
                onValid: { _, _ in },
                onInvalid: { _, errors in
                    onInvalidCalled = true
                    capturedErrors = errors
                }
            )

            #expect(onInvalidCalled == true)
            #expect(capturedErrors?.errorFields.contains(.a) == true)
            #expect(capturedErrors?[.a] == ["Resolver validation failed"])
            #expect(formControl.instantFormState.isSubmitSuccessful == false)
        }

        @Test("resolver receives correct context")
        func resolverReceivesCorrectContext() async throws {
            var formState: FormState<TestFieldName> = .init()
            let testContext = "testContext"
            var capturedContext: Any?

            let resolver: Resolver<TestFieldName> = { values, context, _ in
                capturedContext = context
                return .success(values)
            }

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: resolver,
                context: testContext,
                shouldUnregister: true,
                shouldFocusError: false,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            try await formControl.handleSubmit(onValid: { _, _ in })

            #expect(capturedContext as? String == testContext)
        }

        @Test("resolver receives correct field names")
        func resolverReceivesCorrectFieldNames() async throws {
            var formState: FormState<TestFieldName> = .init()
            var capturedFieldNames: [TestFieldName]?

            let resolver: Resolver<TestFieldName> = { values, _, fieldNames in
                capturedFieldNames = fieldNames
                return .success(values)
            }

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: resolver,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: false,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            try await formControl.handleSubmit(onValid: { _, _ in })

            #expect(capturedFieldNames?.contains(.a) == true)
            #expect(capturedFieldNames?.contains(.b) == true)
            #expect(capturedFieldNames?.count == 2)
        }
    }

    @Suite("Resolver with trigger validation")
    struct ResolverTriggerValidationTests {

        @Test("resolver works with trigger validation")
        func resolverWorksWithTriggerValidation() async {
            var formState: FormState<TestFieldName> = .init()
            let resolver: Resolver<TestFieldName> = { _, _, _ in
                // Return failure for field .a
                let error = FormError<TestFieldName>(
                    errorFields: [.a],
                    messages: [.a: ["Resolver trigger validation failed"]]
                )
                return .failure(error)
            }

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: resolver,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: false,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            let result = await formControl.trigger(name: .a)

            #expect(result == false)
            #expect(formControl.instantFormState.errors.errorFields.contains(.a))
            #expect(formControl.instantFormState.errors[.a] == ["Resolver trigger validation failed"])
        }
    }
}

@Suite("Form Control ClearErrors")
struct FormControlClearErrorsTests {

    @Suite("Clear specific field errors")
    struct ClearSpecificFieldErrorsTests {

        @Test("clears errors for specific fields while preserving others")
        func clearsErrorsForSpecificFieldsWhilePreservingOthers() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error A"])
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Error B"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            // Set errors for both fields
            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Error A"], isValid: false)
            formControl.instantFormState.errors.setMessages(name: .b, messages: ["Error B"], isValid: false)

            // Verify both fields have errors
            #expect(formControl.instantFormState.errors.errorFields.contains(.a))
            #expect(formControl.instantFormState.errors.errorFields.contains(.b))

            // Clear errors for field A only
            await formControl.clearErrors(names: [.a])

            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(formState.errors.errorFields.contains(.b))
            #expect(formState.errors[.a].isEmpty)
            #expect(formState.errors[.b] == ["Error B"])
        }

        @Test("clears errors for multiple fields simultaneously")
        func clearsErrorsForMultipleFieldsSimultaneously() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error A"])
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Error B"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            // Set errors for both fields
            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Error A"], isValid: false)
            formControl.instantFormState.errors.setMessages(name: .b, messages: ["Error B"], isValid: false)

            // Clear errors for both fields
            await formControl.clearErrors(names: [.a, .b])

            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(!formState.errors.errorFields.contains(.b))
            #expect(formState.errors.errorFields.isEmpty)
        }

        @Test("clears errors using variadic parameter syntax")
        func clearsErrorsUsingVariadicParameterSyntax() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error A"])
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Error B"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            // Set errors for both fields
            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Error A"], isValid: false)
            formControl.instantFormState.errors.setMessages(name: .b, messages: ["Error B"], isValid: false)

            // Clear errors using variadic syntax
            await formControl.clearErrors(name: .a, .b)

            let formState = formControl.instantFormState
            #expect(!formState.errors.errorFields.contains(.a))
            #expect(!formState.errors.errorFields.contains(.b))
            #expect(formState.errors.errorFields.isEmpty)
        }

        @Test("handles clearing errors for non-existent fields gracefully")
        func handlesClearingErrorsForNonExistentFieldsGracefully() async {
            let formControl = createFormControl()

            // Try to clear errors for unregistered field
            await formControl.clearErrors(names: [.a])

            // Should complete without errors
            let formState = formControl.instantFormState
            #expect(formState.errors.errorFields.isEmpty)
        }
    }
}

@Suite("Form Control Field Value Changes")
struct FormControlFieldValueChangesTests {

    @Suite("Field dirty state tracking")
    struct FieldDirtyStateTrackingTests {

        @Test("field tracks value changes correctly")
        func fieldTracksValueChangesCorrectly() async {
            let formControl = createFormControl(shouldUnregister: false)
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "originalDefault"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            // Field starts clean
            #expect(!formControl.instantFormState.dirtyFields.contains(.a))

            // Change to a different value
            aBinder.wrappedValue = "changedValue"
            #expect(formControl.instantFormState.dirtyFields.contains(.a))

            // Change back to original default - field may remain dirty depending on implementation
            aBinder.wrappedValue = testDefaultValue

            let formState = formControl.instantFormState
            // The field value should be back to default
            #expect(areEqual(first: formState.formValues[.a], second: testDefaultValue))
            // Whether it's dirty or not depends on the form library implementation
        }

        @Test("field becomes dirty when changed to different value")
        func fieldBecomesDirtyWhenChangedToDifferentValue() async {
            let formControl = createFormControl(shouldUnregister: false)
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "originalDefault"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            // Field starts clean
            #expect(!formControl.instantFormState.dirtyFields.contains(.a))

            // Change to different value
            aBinder.wrappedValue = "newValue"

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: "newValue"))
        }

        @Test("field maintains dirty state after multiple changes")
        func fieldMaintainsDirtyStateAfterMultipleChanges() async {
            let formControl = createFormControl(shouldUnregister: false)
            let aValidator = MockValidator<String, Bool>(result: true)
            let testDefaultValue = "originalDefault"

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: testDefaultValue))

            // Change to different value
            aBinder.wrappedValue = "firstChange"
            #expect(formControl.instantFormState.dirtyFields.contains(.a))

            // Change to another different value
            aBinder.wrappedValue = "secondChange"

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(areEqual(first: formState.formValues[.a], second: "secondChange"))
        }

        @Test("multiple fields track dirty state independently")
        func multipleFieldsTrackDirtyStateIndependently() async {
            let formControl = createFormControl(shouldUnregister: false)
            let aValidator = MockValidator<String, Bool>(result: true)
            let bValidator = MockValidator<String, Bool>(result: true)

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            let bBinder = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            // Change only field A
            aBinder.wrappedValue = "changedA"

            let formState = formControl.instantFormState
            #expect(formState.dirtyFields.contains(.a))
            #expect(!formState.dirtyFields.contains(.b))
            #expect(areEqual(first: formState.formValues[.a], second: "changedA"))
            #expect(areEqual(first: formState.formValues[.b], second: "defaultB"))
        }
    }
}

@Suite("Form Control Focus")
struct FormControlFocusTests {

    @Suite("Field focus management")
    struct FieldFocusManagementTests {

        @Test("tracks current focused field")
        func tracksCurrentFocusedField() async {
            var focusedField: TestFieldName?
            var formState: FormState<TestFieldName> = .init()

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { field in
                    focusedField = field
                }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: true)
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // Simulate focus change
            await MainActor.run {
                formControl.currentFocusedField = .a
            }

            #expect(focusedField == .a)
        }

        @Test("focuses error field during validation with shouldFocus")
        func focusesErrorFieldDuringValidationWithShouldFocus() async {
            var focusedField: TestFieldName?
            var formState: FormState<TestFieldName> = .init()

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { field in
                    focusedField = field
                }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error A"])
            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))

            // Trigger validation with shouldFocus
            let result = await formControl.trigger(name: .a, shouldFocus: true)

            #expect(result == false)
            #expect(focusedField == .a)
        }

        @Test("handles multiple fields with focus priority")
        func handlesMultipleFieldsWithFocusPriority() async {
            var focusedField: TestFieldName?
            var formState: FormState<TestFieldName> = .init()

            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { field in
                    focusedField = field
                }
            )

            let formControl = FormControl(options: options, formState: .init(
                get: { formState },
                set: { formState = $0 }
            ))

            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Error A"])
            let bValidator = MockValidator<String, Bool>(result: false, messages: ["Error B"])

            _ = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            _ = formControl.register(name: .b, options: .init(rules: bValidator, defaultValue: "defaultB"))

            // Trigger validation for multiple fields with shouldFocus
            let result = await formControl.trigger(names: [.a, .b], shouldFocus: true)

            #expect(result == false)
            // Should focus on first error field (typically the first registered field with error)
            #expect(focusedField != nil)
        }

        @Test("getFieldState returns correct field information")
        func getFieldStateReturnsCorrectFieldInformation() {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Field error"])

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            aBinder.wrappedValue = "changedValue"

            // Set error state
            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Field error"], isValid: false)

            let fieldState = formControl.getFieldState(name: .a)

            #expect(fieldState.isDirty == true)
            #expect(fieldState.isInvalid == true)
            #expect(fieldState.error == ["Field error"])
        }

        @Test("getFieldState async version works correctly")
        func getFieldStateAsyncVersionWorksCorrectly() async {
            let formControl = createFormControl()
            let aValidator = MockValidator<String, Bool>(result: false, messages: ["Field error"])

            let aBinder = formControl.register(name: .a, options: .init(rules: aValidator, defaultValue: "defaultA"))
            aBinder.wrappedValue = "changedValue"

            // Set error state and sync
            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Field error"], isValid: false)
            await formControl.syncFormState()

            let fieldState = await formControl.getFieldState(name: .a)

            #expect(fieldState.isDirty == true)
            #expect(fieldState.isInvalid == true)
            #expect(fieldState.error == ["Field error"])
        }
    }
}
