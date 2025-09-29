//
//  FieldTypesTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

@testable import FormHook
import Foundation
import SwiftUI
import Testing

enum TestFieldTypeName: String, Hashable {
    case username
    case email
    case password
    case confirmPassword
}

@Suite("RegisterOption")
struct RegisterOptionTests {

    @Suite("Initialization")
    struct InitializationTests {

        @Test("creates with all parameters")
        func createsWithAllParameters() {
            let validator = NoopValidator<String>()
            let option = RegisterOption(
                fieldOrdinal: 5,
                rules: validator,
                defaultValue: "test",
                shouldUnregister: false
            )

            #expect(option.fieldOrdinal == 5)
            #expect(option.defaultValue == "test")
            #expect(option.shouldUnregister == false)
        }

        @Test("creates with default parameters")
        func createsWithDefaultParameters() {
            let validator = NoopValidator<String>()
            let option = RegisterOption(
                rules: validator,
                defaultValue: "default"
            )

            #expect(option.fieldOrdinal == nil)
            #expect(option.defaultValue == "default")
            #expect(option.shouldUnregister == true)
        }

        @Test("works with different value types")
        func worksWithDifferentValueTypes() {
            let stringOption = RegisterOption(
                rules: NoopValidator<String>(),
                defaultValue: "string"
            )
            #expect(stringOption.defaultValue == "string")

            let intOption = RegisterOption(
                rules: NoopValidator<Int>(),
                defaultValue: 42
            )
            #expect(intOption.defaultValue == 42)

            let boolOption = RegisterOption(
                rules: NoopValidator<Bool>(),
                defaultValue: true
            )
            #expect(boolOption.defaultValue == true)

            let arrayOption = RegisterOption(
                rules: NoopValidator<[String]>(),
                defaultValue: ["item1", "item2"]
            )
            #expect(arrayOption.defaultValue == ["item1", "item2"])
        }
    }
}

@Suite("UnregisterOption")
struct UnregisterOptionTests {

    @Suite("Individual options")
    struct IndividualOptionTests {

        @Test("has correct raw values")
        func hasCorrectRawValues() {
            #expect(UnregisterOption.keepDirty.rawValue == 1)
            #expect(UnregisterOption.keepIsValid.rawValue == 2)
            #expect(UnregisterOption.keepError.rawValue == 4)
            #expect(UnregisterOption.keepValue.rawValue == 8)
            #expect(UnregisterOption.keepDefaultValue.rawValue == 16)
        }

        @Test("supports individual option checks")
        func supportsIndividualOptionChecks() {
            let options: UnregisterOption = .keepDirty
            #expect(options.contains(.keepDirty) == true)
            #expect(options.contains(.keepError) == false)
        }
    }

    @Suite("Combination options")
    struct CombinationOptionTests {

        @Test("supports multiple option combinations")
        func supportsMultipleOptionCombinations() {
            let options: UnregisterOption = [.keepDirty, .keepError]
            #expect(options.contains(.keepDirty) == true)
            #expect(options.contains(.keepError) == true)
            #expect(options.contains(.keepValue) == false)
        }

        @Test("has correct all option")
        func hasCorrectAllOption() {
            let allOptions = UnregisterOption.all
            #expect(allOptions.contains(.keepDirty) == true)
            #expect(allOptions.contains(.keepIsValid) == true)
            #expect(allOptions.contains(.keepError) == true)
            #expect(allOptions.contains(.keepValue) == true)
            #expect(allOptions.contains(.keepDefaultValue) == true)
        }

        @Test("supports empty option set")
        func supportsEmptyOptionSet() {
            let emptyOptions: UnregisterOption = []
            #expect(emptyOptions.contains(.keepDirty) == false)
            #expect(emptyOptions.contains(.keepError) == false)
        }
    }

    @Suite("Option set operations")
    struct OptionSetOperationTests {

        @Test("supports union operations")
        func supportsUnionOperations() {
            let options1: UnregisterOption = .keepDirty
            let options2: UnregisterOption = .keepError
            let combined = options1.union(options2)

            #expect(combined.contains(.keepDirty) == true)
            #expect(combined.contains(.keepError) == true)
        }

        @Test("supports intersection operations")
        func supportsIntersectionOperations() {
            let options1: UnregisterOption = [.keepDirty, .keepError]
            let options2: UnregisterOption = [.keepError, .keepValue]
            let intersection = options1.intersection(options2)

            #expect(intersection.contains(.keepError) == true)
            #expect(intersection.contains(.keepDirty) == false)
            #expect(intersection.contains(.keepValue) == false)
        }

        @Test("supports subtraction operations")
        func supportsSubtractionOperations() {
            let options: UnregisterOption = [.keepDirty, .keepError, .keepValue]
            let toRemove: UnregisterOption = [.keepError]
            let result = options.subtracting(toRemove)

            #expect(result.contains(.keepDirty) == true)
            #expect(result.contains(.keepError) == false)
            #expect(result.contains(.keepValue) == true)
        }
    }
}

@Suite("ResetOption")
struct ResetOptionTests {

    @Suite("Individual options")
    struct IndividualOptionTests {

        @Test("has correct raw values")
        func hasCorrectRawValues() {
            #expect(ResetOption.keepDirty.rawValue == 1)
            #expect(ResetOption.keepIsSubmitted.rawValue == 2)
            #expect(ResetOption.keepIsValid.rawValue == 4)
            #expect(ResetOption.keepErrors.rawValue == 8)
            #expect(ResetOption.keepValues.rawValue == 16)
            #expect(ResetOption.keepDefaultValues.rawValue == 32)
            #expect(ResetOption.keepSubmitCount.rawValue == 64)
        }

        @Test("supports individual option checks")
        func supportsIndividualOptionChecks() {
            let options: ResetOption = .keepValues
            #expect(options.contains(.keepValues) == true)
            #expect(options.contains(.keepErrors) == false)
        }
    }

    @Suite("Combination options")
    struct CombinationOptionTests {

        @Test("supports multiple option combinations")
        func supportsMultipleOptionCombinations() {
            let options: ResetOption = [.keepDirty, .keepErrors, .keepValues]
            #expect(options.contains(.keepDirty) == true)
            #expect(options.contains(.keepErrors) == true)
            #expect(options.contains(.keepValues) == true)
            #expect(options.contains(.keepIsValid) == false)
        }

        @Test("has correct all option")
        func hasCorrectAllOption() {
            let allOptions = ResetOption.all
            #expect(allOptions.contains(.keepDirty) == true)
            #expect(allOptions.contains(.keepIsSubmitted) == true)
            #expect(allOptions.contains(.keepIsValid) == true)
            #expect(allOptions.contains(.keepErrors) == true)
            #expect(allOptions.contains(.keepValues) == true)
            #expect(allOptions.contains(.keepDefaultValues) == true)
            #expect(allOptions.contains(.keepSubmitCount) == true)
        }
    }

    @Suite("Typical use cases")
    struct TypicalUseCaseTests {

        @Test("keeps form data but resets validation")
        func keepsFormDataButResetsValidation() {
            let options: ResetOption = [.keepValues, .keepDefaultValues]
            #expect(options.contains(.keepValues) == true)
            #expect(options.contains(.keepDefaultValues) == true)
            #expect(options.contains(.keepErrors) == false)
            #expect(options.contains(.keepIsValid) == false)
        }

        @Test("keeps validation state but resets form data")
        func keepsValidationStateButResetsFormData() {
            let options: ResetOption = [.keepIsValid, .keepErrors]
            #expect(options.contains(.keepIsValid) == true)
            #expect(options.contains(.keepErrors) == true)
            #expect(options.contains(.keepValues) == false)
            #expect(options.contains(.keepDirty) == false)
        }
    }
}

@Suite("SingleResetOption")
struct SingleResetOptionTests {

    @Suite("Individual options")
    struct IndividualOptionTests {

        @Test("has correct raw values")
        func hasCorrectRawValues() {
            #expect(SingleResetOption.keepDirty.rawValue == 1)
            #expect(SingleResetOption.keepError.rawValue == 2)
        }

        @Test("supports individual option checks")
        func supportsIndividualOptionChecks() {
            let options: SingleResetOption = .keepDirty
            #expect(options.contains(.keepDirty) == true)
            #expect(options.contains(.keepError) == false)
        }
    }

    @Suite("Combination options")
    struct CombinationOptionTests {

        @Test("supports multiple option combinations")
        func supportsMultipleOptionCombinations() {
            let options: SingleResetOption = [.keepDirty, .keepError]
            #expect(options.contains(.keepDirty) == true)
            #expect(options.contains(.keepError) == true)
        }

        @Test("has correct all option")
        func hasCorrectAllOption() {
            let allOptions = SingleResetOption.all
            #expect(allOptions.contains(.keepDirty) == true)
            #expect(allOptions.contains(.keepError) == true)
        }

        @Test("supports empty option set")
        func supportsEmptyOptionSet() {
            let emptyOptions: SingleResetOption = []
            #expect(emptyOptions.contains(.keepDirty) == false)
            #expect(emptyOptions.contains(.keepError) == false)
        }
    }
}

@Suite("SetValueOption")
struct SetValueOptionTests {

    @Suite("Individual options")
    struct IndividualOptionTests {

        @Test("has correct raw values")
        func hasCorrectRawValues() {
            #expect(SetValueOption.shouldValidate.rawValue == 1)
            #expect(SetValueOption.shouldDirty.rawValue == 2)
        }

        @Test("supports individual option checks")
        func supportsIndividualOptionChecks() {
            let options: SetValueOption = .shouldValidate
            #expect(options.contains(.shouldValidate) == true)
            #expect(options.contains(.shouldDirty) == false)
        }
    }

    @Suite("Combination options")
    struct CombinationOptionTests {

        @Test("supports multiple option combinations")
        func supportsMultipleOptionCombinations() {
            let options: SetValueOption = [.shouldValidate, .shouldDirty]
            #expect(options.contains(.shouldValidate) == true)
            #expect(options.contains(.shouldDirty) == true)
        }

        @Test("has correct all option")
        func hasCorrectAllOption() {
            let allOptions = SetValueOption.all
            #expect(allOptions.contains(.shouldValidate) == true)
            #expect(allOptions.contains(.shouldDirty) == true)
        }

        @Test("supports empty option set")
        func supportsEmptyOptionSet() {
            let emptyOptions: SetValueOption = []
            #expect(emptyOptions.contains(.shouldValidate) == false)
            #expect(emptyOptions.contains(.shouldDirty) == false)
        }
    }

    @Suite("Typical use cases")
    struct TypicalUseCaseTests {

        @Test("validates without marking dirty")
        func validatesWithoutMarkingDirty() {
            let options: SetValueOption = .shouldValidate
            #expect(options.contains(.shouldValidate) == true)
            #expect(options.contains(.shouldDirty) == false)
        }

        @Test("marks dirty without validating")
        func marksDirtyWithoutValidating() {
            let options: SetValueOption = .shouldDirty
            #expect(options.contains(.shouldDirty) == true)
            #expect(options.contains(.shouldValidate) == false)
        }

        @Test("both validates and marks dirty")
        func bothValidatesAndMarksDirty() {
            let options: SetValueOption = .all
            #expect(options.contains(.shouldValidate) == true)
            #expect(options.contains(.shouldDirty) == true)
        }
    }
}

@Suite("FieldOption")
struct FieldOptionTests {

    @Suite("Initialization and properties")
    struct InitializationTests {

        @Test("stores field name and value binding")
        func storesFieldNameAndValueBinding() {
            var testValue = "initial"
            let binding = Binding(
                get: { testValue },
                set: { testValue = $0 }
            )
            let fieldOption = FieldOption(
                name: TestFieldTypeName.username,
                value: binding
            )

            #expect(fieldOption.name == .username)
            #expect(fieldOption.value.wrappedValue == "initial")
        }

        @Test("supports value binding modifications")
        func supportsValueBindingModifications() {
            // Create a manual binding for testing since @State doesn't work in test context
            var testValue = "initial"
            let binding = Binding(
                get: { testValue },
                set: { testValue = $0 }
            )
            let fieldOption = FieldOption(
                name: TestFieldTypeName.email,
                value: binding
            )

            fieldOption.value.wrappedValue = "updated"
            #expect(testValue == "updated")
            #expect(fieldOption.value.wrappedValue == "updated")
        }

        @Test("works with different value types")
        func worksWithDifferentValueTypes() {
            var stringValue = "text"
            var intValue = 42
            var boolValue = true

            let stringBinding = Binding(get: { stringValue }, set: { stringValue = $0 })
            let intBinding = Binding(get: { intValue }, set: { intValue = $0 })
            let boolBinding = Binding(get: { boolValue }, set: { boolValue = $0 })

            let stringOption = FieldOption(name: TestFieldTypeName.username, value: stringBinding)
            let intOption = FieldOption(name: TestFieldTypeName.username, value: intBinding)
            let boolOption = FieldOption(name: TestFieldTypeName.username, value: boolBinding)

            #expect(stringOption.value.wrappedValue == "text")
            #expect(intOption.value.wrappedValue == 42)
            #expect(boolOption.value.wrappedValue == true)
        }
    }
}

@Suite("ControllerRenderOption")
struct ControllerRenderOptionTests {

    @Suite("Typealias properties")
    struct TypealiasPropertyTests {

        @Test("provides access to field, fieldState, and formState")
        func providesAccessToFieldFieldStateAndFormState() {
            var testValue = "test"
            let binding = Binding(get: { testValue }, set: { testValue = $0 })
            let fieldOption = FieldOption(
                name: TestFieldTypeName.username,
                value: binding
            )
            let fieldState = FieldState(isDirty: true, isInvalid: false, error: [])
            let formState = FormState<TestFieldTypeName>()

            let renderOption: ControllerRenderOption<TestFieldTypeName, String> = (
                field: fieldOption,
                fieldState: fieldState,
                formState: formState
            )

            #expect(renderOption.field.name == .username)
            #expect(renderOption.field.value.wrappedValue == "test")
            #expect(renderOption.fieldState.isDirty == true)
            #expect(renderOption.fieldState.isInvalid == false)
            #expect(renderOption.formState.isValid == true)
        }

        @Test("supports destructuring")
        func supportsDestructuring() {
            var testValue = "destructure"
            let binding = Binding(get: { testValue }, set: { testValue = $0 })
            let fieldOption = FieldOption(
                name: TestFieldTypeName.password,
                value: binding
            )
            let fieldState = FieldState(isDirty: false, isInvalid: true, error: ["Error"])
            let formState = FormState<TestFieldTypeName>()

            let renderOption: ControllerRenderOption<TestFieldTypeName, String> = (
                field: fieldOption,
                fieldState: fieldState,
                formState: formState
            )

            let (field, fieldState2, formState2) = renderOption

            #expect(field.name == .password)
            #expect(field.value.wrappedValue == "destructure")
            #expect(fieldState2.isDirty == false)
            #expect(fieldState2.isInvalid == true)
            #expect(fieldState2.error == ["Error"])
            #expect(formState2.isValid == true)
        }
    }
}
