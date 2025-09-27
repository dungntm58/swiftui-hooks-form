//
//  FieldTypesTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

import Foundation
import SwiftUI
import Quick
import Nimble
@testable import FormHook

enum TestFieldTypeName: String, Hashable {
    case username
    case email
    case password
    case confirmPassword
}

final class FieldTypesTests: QuickSpec {
    override func spec() {
        registerOptionSpecs()
        unregisterOptionSpecs()
        resetOptionSpecs()
        singleResetOptionSpecs()
        setValueOptionSpecs()
        fieldOptionSpecs()
        controllerRenderOptionSpecs()
    }

    func registerOptionSpecs() {
        describe("RegisterOption") {
            context("initialization") {
                it("creates with all parameters") {
                    let validator = NoopValidator<String>()
                    let option = RegisterOption(
                        fieldOrdinal: 5,
                        rules: validator,
                        defaultValue: "test",
                        shouldUnregister: false
                    )

                    expect(option.fieldOrdinal) == 5
                    expect(option.defaultValue) == "test"
                    expect(option.shouldUnregister) == false
                }

                it("creates with default parameters") {
                    let validator = NoopValidator<String>()
                    let option = RegisterOption(
                        rules: validator,
                        defaultValue: "default"
                    )

                    expect(option.fieldOrdinal).to(beNil())
                    expect(option.defaultValue) == "default"
                    expect(option.shouldUnregister) == true
                }

                it("works with different value types") {
                    let stringOption = RegisterOption(
                        rules: NoopValidator<String>(),
                        defaultValue: "string"
                    )
                    expect(stringOption.defaultValue) == "string"

                    let intOption = RegisterOption(
                        rules: NoopValidator<Int>(),
                        defaultValue: 42
                    )
                    expect(intOption.defaultValue) == 42

                    let boolOption = RegisterOption(
                        rules: NoopValidator<Bool>(),
                        defaultValue: true
                    )
                    expect(boolOption.defaultValue) == true

                    let arrayOption = RegisterOption(
                        rules: NoopValidator<[String]>(),
                        defaultValue: ["item1", "item2"]
                    )
                    expect(arrayOption.defaultValue) == ["item1", "item2"]
                }
            }
        }
    }

    func unregisterOptionSpecs() {
        describe("UnregisterOption") {
            context("individual options") {
                it("has correct raw values") {
                    expect(UnregisterOption.keepDirty.rawValue) == 1
                    expect(UnregisterOption.keepIsValid.rawValue) == 2
                    expect(UnregisterOption.keepError.rawValue) == 4
                    expect(UnregisterOption.keepValue.rawValue) == 8
                    expect(UnregisterOption.keepDefaultValue.rawValue) == 16
                }

                it("supports individual option checks") {
                    let options: UnregisterOption = .keepDirty
                    expect(options.contains(.keepDirty)) == true
                    expect(options.contains(.keepError)) == false
                }
            }

            context("combination options") {
                it("supports multiple option combinations") {
                    let options: UnregisterOption = [.keepDirty, .keepError]
                    expect(options.contains(.keepDirty)) == true
                    expect(options.contains(.keepError)) == true
                    expect(options.contains(.keepValue)) == false
                }

                it("has correct all option") {
                    let allOptions = UnregisterOption.all
                    expect(allOptions.contains(.keepDirty)) == true
                    expect(allOptions.contains(.keepIsValid)) == true
                    expect(allOptions.contains(.keepError)) == true
                    expect(allOptions.contains(.keepValue)) == true
                    expect(allOptions.contains(.keepDefaultValue)) == true
                }

                it("supports empty option set") {
                    let emptyOptions: UnregisterOption = []
                    expect(emptyOptions.contains(.keepDirty)) == false
                    expect(emptyOptions.contains(.keepError)) == false
                }
            }

            context("option set operations") {
                it("supports union operations") {
                    let options1: UnregisterOption = .keepDirty
                    let options2: UnregisterOption = .keepError
                    let combined = options1.union(options2)

                    expect(combined.contains(.keepDirty)) == true
                    expect(combined.contains(.keepError)) == true
                }

                it("supports intersection operations") {
                    let options1: UnregisterOption = [.keepDirty, .keepError]
                    let options2: UnregisterOption = [.keepError, .keepValue]
                    let intersection = options1.intersection(options2)

                    expect(intersection.contains(.keepError)) == true
                    expect(intersection.contains(.keepDirty)) == false
                    expect(intersection.contains(.keepValue)) == false
                }

                it("supports subtraction operations") {
                    let options: UnregisterOption = [.keepDirty, .keepError, .keepValue]
                    let toRemove: UnregisterOption = [.keepError]
                    let result = options.subtracting(toRemove)

                    expect(result.contains(.keepDirty)) == true
                    expect(result.contains(.keepError)) == false
                    expect(result.contains(.keepValue)) == true
                }
            }
        }
    }

    func resetOptionSpecs() {
        describe("ResetOption") {
            context("individual options") {
                it("has correct raw values") {
                    expect(ResetOption.keepDirty.rawValue) == 1
                    expect(ResetOption.keepIsSubmitted.rawValue) == 2
                    expect(ResetOption.keepIsValid.rawValue) == 4
                    expect(ResetOption.keepErrors.rawValue) == 8
                    expect(ResetOption.keepValues.rawValue) == 16
                    expect(ResetOption.keepDefaultValues.rawValue) == 32
                    expect(ResetOption.keepSubmitCount.rawValue) == 64
                }

                it("supports individual option checks") {
                    let options: ResetOption = .keepValues
                    expect(options.contains(.keepValues)) == true
                    expect(options.contains(.keepErrors)) == false
                }
            }

            context("combination options") {
                it("supports multiple option combinations") {
                    let options: ResetOption = [.keepDirty, .keepErrors, .keepValues]
                    expect(options.contains(.keepDirty)) == true
                    expect(options.contains(.keepErrors)) == true
                    expect(options.contains(.keepValues)) == true
                    expect(options.contains(.keepIsValid)) == false
                }

                it("has correct all option") {
                    let allOptions = ResetOption.all
                    expect(allOptions.contains(.keepDirty)) == true
                    expect(allOptions.contains(.keepIsSubmitted)) == true
                    expect(allOptions.contains(.keepIsValid)) == true
                    expect(allOptions.contains(.keepErrors)) == true
                    expect(allOptions.contains(.keepValues)) == true
                    expect(allOptions.contains(.keepDefaultValues)) == true
                    expect(allOptions.contains(.keepSubmitCount)) == true
                }
            }

            context("typical use cases") {
                it("keeps form data but resets validation") {
                    let options: ResetOption = [.keepValues, .keepDefaultValues]
                    expect(options.contains(.keepValues)) == true
                    expect(options.contains(.keepDefaultValues)) == true
                    expect(options.contains(.keepErrors)) == false
                    expect(options.contains(.keepIsValid)) == false
                }

                it("keeps validation state but resets form data") {
                    let options: ResetOption = [.keepIsValid, .keepErrors]
                    expect(options.contains(.keepIsValid)) == true
                    expect(options.contains(.keepErrors)) == true
                    expect(options.contains(.keepValues)) == false
                    expect(options.contains(.keepDirty)) == false
                }
            }
        }
    }

    func singleResetOptionSpecs() {
        describe("SingleResetOption") {
            context("individual options") {
                it("has correct raw values") {
                    expect(SingleResetOption.keepDirty.rawValue) == 1
                    expect(SingleResetOption.keepError.rawValue) == 2
                }

                it("supports individual option checks") {
                    let options: SingleResetOption = .keepDirty
                    expect(options.contains(.keepDirty)) == true
                    expect(options.contains(.keepError)) == false
                }
            }

            context("combination options") {
                it("supports multiple option combinations") {
                    let options: SingleResetOption = [.keepDirty, .keepError]
                    expect(options.contains(.keepDirty)) == true
                    expect(options.contains(.keepError)) == true
                }

                it("has correct all option") {
                    let allOptions = SingleResetOption.all
                    expect(allOptions.contains(.keepDirty)) == true
                    expect(allOptions.contains(.keepError)) == true
                }

                it("supports empty option set") {
                    let emptyOptions: SingleResetOption = []
                    expect(emptyOptions.contains(.keepDirty)) == false
                    expect(emptyOptions.contains(.keepError)) == false
                }
            }
        }
    }

    func setValueOptionSpecs() {
        describe("SetValueOption") {
            context("individual options") {
                it("has correct raw values") {
                    expect(SetValueOption.shouldValidate.rawValue) == 1
                    expect(SetValueOption.shouldDirty.rawValue) == 2
                }

                it("supports individual option checks") {
                    let options: SetValueOption = .shouldValidate
                    expect(options.contains(.shouldValidate)) == true
                    expect(options.contains(.shouldDirty)) == false
                }
            }

            context("combination options") {
                it("supports multiple option combinations") {
                    let options: SetValueOption = [.shouldValidate, .shouldDirty]
                    expect(options.contains(.shouldValidate)) == true
                    expect(options.contains(.shouldDirty)) == true
                }

                it("has correct all option") {
                    let allOptions = SetValueOption.all
                    expect(allOptions.contains(.shouldValidate)) == true
                    expect(allOptions.contains(.shouldDirty)) == true
                }

                it("supports empty option set") {
                    let emptyOptions: SetValueOption = []
                    expect(emptyOptions.contains(.shouldValidate)) == false
                    expect(emptyOptions.contains(.shouldDirty)) == false
                }
            }

            context("typical use cases") {
                it("validates without marking dirty") {
                    let options: SetValueOption = .shouldValidate
                    expect(options.contains(.shouldValidate)) == true
                    expect(options.contains(.shouldDirty)) == false
                }

                it("marks dirty without validating") {
                    let options: SetValueOption = .shouldDirty
                    expect(options.contains(.shouldDirty)) == true
                    expect(options.contains(.shouldValidate)) == false
                }

                it("both validates and marks dirty") {
                    let options: SetValueOption = .all
                    expect(options.contains(.shouldValidate)) == true
                    expect(options.contains(.shouldDirty)) == true
                }
            }
        }
    }

    func fieldOptionSpecs() {
        describe("FieldOption") {
            context("initialization and properties") {
                it("stores field name and value binding") {
                    @State var testValue = "initial"
                    let fieldOption = FieldOption(
                        name: TestFieldTypeName.username,
                        value: $testValue
                    )

                    expect(fieldOption.name) == .username
                    expect(fieldOption.value.wrappedValue) == "initial"
                }

                it("supports value binding modifications") {
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
                    expect(testValue) == "updated"
                    expect(fieldOption.value.wrappedValue) == "updated"
                }

                it("works with different value types") {
                    @State var stringValue = "text"
                    @State var intValue = 42
                    @State var boolValue = true

                    let stringOption = FieldOption(name: TestFieldTypeName.username, value: $stringValue)
                    let intOption = FieldOption(name: TestFieldTypeName.username, value: $intValue)
                    let boolOption = FieldOption(name: TestFieldTypeName.username, value: $boolValue)

                    expect(stringOption.value.wrappedValue) == "text"
                    expect(intOption.value.wrappedValue) == 42
                    expect(boolOption.value.wrappedValue) == true
                }
            }
        }
    }

    func controllerRenderOptionSpecs() {
        describe("ControllerRenderOption") {
            context("typealias properties") {
                it("provides access to field, fieldState, and formState") {
                    @State var testValue = "test"
                    let fieldOption = FieldOption(
                        name: TestFieldTypeName.username,
                        value: $testValue
                    )
                    let fieldState = FieldState(isDirty: true, isInvalid: false, error: [])
                    let formState = FormState<TestFieldTypeName>()

                    let renderOption: ControllerRenderOption<TestFieldTypeName, String> = (
                        field: fieldOption,
                        fieldState: fieldState,
                        formState: formState
                    )

                    expect(renderOption.field.name) == .username
                    expect(renderOption.field.value.wrappedValue) == "test"
                    expect(renderOption.fieldState.isDirty) == true
                    expect(renderOption.fieldState.isInvalid) == false
                    expect(renderOption.formState.isValid) == true
                }

                it("supports destructuring") {
                    @State var testValue = "destructure"
                    let fieldOption = FieldOption(
                        name: TestFieldTypeName.password,
                        value: $testValue
                    )
                    let fieldState = FieldState(isDirty: false, isInvalid: true, error: ["Error"])
                    let formState = FormState<TestFieldTypeName>()

                    let renderOption: ControllerRenderOption<TestFieldTypeName, String> = (
                        field: fieldOption,
                        fieldState: fieldState,
                        formState: formState
                    )

                    let (field, fieldState2, formState2) = renderOption

                    expect(field.name) == .password
                    expect(field.value.wrappedValue) == "destructure"
                    expect(fieldState2.isDirty) == false
                    expect(fieldState2.isInvalid) == true
                    expect(fieldState2.error) == ["Error"]
                    expect(formState2.isValid) == true
                }
            }
        }
    }
}

// Helper FieldState for testing - using the internal initializer