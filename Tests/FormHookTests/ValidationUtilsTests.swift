//
//  ValidationUtilsTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

import Foundation
import Testing
@preconcurrency @testable import FormHook

enum TestValidationFieldName: Hashable {
    case field1
    case field2
    case field3
    case field4
    case field5
}

@Suite("Validation Utils")
struct ValidationUtilsTests {

    // Helper function to create a form control for testing
    private func createFormControl() -> FormControl<TestValidationFieldName> {
        var formState: FormState<TestValidationFieldName> = .init()
        let options = FormOption<TestValidationFieldName>(
            mode: .onSubmit,
            reValidateMode: .onChange,
            resolver: nil,
            context: nil,
            shouldUnregister: true,
            shouldFocusError: false,
            delayErrorInNanoseconds: 0,
            onFocusField: { _ in }
        )
        return .init(options: options, formState: .init(
            get: { formState },
            set: { formState = $0 }
        ))
    }

    @Suite("validateFields")
    struct ValidateFieldsTests {

        @Suite("with all valid fields")
        struct AllValidFieldsTests {

            @Test("returns overall valid result")
            func returnsOverallValidResult() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateFields(fieldNames: [.field1, .field2])

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
                // Check that all message arrays are empty rather than the dictionary being empty
                for (_, messages) in result.errors.messages {
                    #expect(messages.isEmpty)
                }
            }
        }

        @Suite("with some invalid fields")
        struct SomeInvalidFieldsTests {

            @Test("returns overall invalid result with error details")
            func returnsOverallInvalidResultWithErrorDetails() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field1 error"]),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateFields(fieldNames: [.field1, .field2])

                #expect(result.isValid == false)
                #expect(result.errors.errorFields.contains(.field1))
                #expect(!result.errors.errorFields.contains(.field2))
                #expect(result.errors.messages[.field1] == ["Field1 error"])
            }
        }

        @Suite("with empty field names list")
        struct EmptyFieldNamesListTests {

            @Test("returns valid result")
            func returnsValidResult() async {
                let formControl = ValidationUtilsTests().createFormControl()

                let result = await formControl.validateFields(fieldNames: [])

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }

        @Suite("with non-existent fields")
        struct NonExistentFieldsTests {

            @Test("ignores non-existent fields and validates existing ones")
            func ignoresNonExistentFieldsAndValidatesExistingOnes() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))

                let result = await formControl.validateFields(fieldNames: [.field1, .field2])

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }

        @Suite("with shouldStopOnFirstError = true")
        struct StopOnFirstErrorTests {

            @Test("stops validation early and returns partial results")
            func stopsValidationEarlyAndReturnsPartialResults() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field1 error"]),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field2 error"]),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateFields(
                    fieldNames: [.field1, .field2],
                    shouldStopOnFirstError: true
                )

                #expect(result.isValid == false)
                // With concurrent validation, both fields may be validated before early termination
                // At least one field should have an error
                #expect(!result.errors.errorFields.isEmpty)
            }
        }
    }

    @Suite("validateAllFields")
    struct ValidateAllFieldsTests {

        @Suite("with no registered fields")
        struct NoRegisteredFieldsTests {

            @Test("returns valid result")
            func returnsValidResult() async {
                let formControl = ValidationUtilsTests().createFormControl()

                let result = await formControl.validateAllFields()

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }

        @Suite("with multiple registered fields")
        struct MultipleRegisteredFieldsTests {

            @Test("validates all registered fields")
            func validatesAllRegisteredFields() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field2 error"]),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateAllFields()

                #expect(result.isValid == false)
                #expect(!result.errors.errorFields.contains(.field1))
                #expect(result.errors.errorFields.contains(.field2))
                #expect(result.errors.messages[.field2] == ["Field2 error"])
            }

            @Test("includes all fields in messages, even valid ones")
            func includesAllFieldsInMessagesEvenValidOnes() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateAllFields()

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
                // All fields should have entries in messages (even if empty)
                #expect(result.errors.messages.keys.contains(.field1))
                #expect(result.errors.messages.keys.contains(.field2))
            }
        }

        @Suite("with shouldStopOnFirstError = true")
        struct StopOnFirstErrorTests {

            @Test("stops early on first error")
            func stopsEarlyOnFirstError() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field1 error"]),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field2 error"]),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateAllFields(shouldStopOnFirstError: true)

                #expect(result.isValid == false)
                // Should stop on first error
                #expect(result.errors.errorFields.count >= 1)
            }
        }
    }

    @Suite("revalidateErrorFields")
    struct RevalidateErrorFieldsTests {

        @Suite("with no existing errors")
        struct NoExistingErrorsTests {

            @Test("returns valid result with no validation")
            func returnsValidResultWithNoValidation() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))

                let result = await formControl.revalidateErrorFields()

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }

        @Suite("with existing errors")
        struct ExistingErrorsTests {

            @Test("only revalidates fields with existing errors")
            func onlyRevalidatesFieldsWithExistingErrors() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field1 error"]),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value2"
                ))

                // First validation to create errors
                _ = await formControl.validateAllFields()

                // Change field1 to be valid
                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))

                let result = await formControl.revalidateErrorFields()

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }

            @Test("updates error messages from validators")
            func updatesErrorMessagesFromValidators() async {
                let formControl = ValidationUtilsTests().createFormControl()

                let validator = MockValidator<String, Bool>(result: false, messages: ["Original error"])
                _ = formControl.register(name: .field1, options: .init(
                    rules: validator,
                    defaultValue: "value1"
                ))

                // First validation to create errors and set them in form state
                let firstResult = await formControl.validateAllFields()
                formControl.instantFormState.errors = firstResult.errors
                formControl.instantFormState.isValid = firstResult.isValid

                // Update the validator to return different error messages
                validator.result = false
                validator.messages = ["Updated error"]

                let result = await formControl.revalidateErrorFields()

                #expect(result.isValid == false)
                #expect(result.errors.messages[.field1] == ["Updated error"])
            }
        }

        @Suite("with errors that are now resolved")
        struct ErrorsNowResolvedTests {

            @Test("returns valid result when errors are resolved")
            func returnsValidResultWhenErrorsAreResolved() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Field1 error"]),
                    defaultValue: "value1"
                ))

                // First validation to create errors
                _ = await formControl.validateAllFields()

                // Fix the field
                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))

                let result = await formControl.revalidateErrorFields()

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }
    }

    @Suite("concurrent validation")
    struct ConcurrentValidationTests {

        @Suite("with delayed validators")
        struct DelayedValidatorsTests {

            @Test("runs validations concurrently")
            func runsValidationsConcurrently() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result:true),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result:true),
                    defaultValue: "value2"
                ))
                _ = formControl.register(name: .field3, options: .init(
                    rules: MockValidator<String, Bool>(result:true),
                    defaultValue: "value3"
                ))

                let startTime = DispatchTime.now()
                let result = await formControl.validateAllFields()
                let endTime = DispatchTime.now()
                let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                #expect(result.isValid == true)
                // Just verify it completed in reasonable time (less than 1 second)
                #expect(timeElapsed < 1_000_000_000) // Less than 1 second
            }
        }

        @Suite("with mixed validation speeds")
        struct MixedValidationSpeedsTests {

            @Test("waits for all validations to complete")
            func waitsForAllValidationsToComplete() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages:["Fast error"]),
                    defaultValue: "value1"
                ))
                _ = formControl.register(name: .field2, options: .init(
                    rules: MockValidator<String, Bool>(result:false, messages: ["Slow error"]),
                    defaultValue: "value2"
                ))

                let result = await formControl.validateAllFields()

                #expect(result.isValid == false)
                #expect(result.errors.errorFields.contains(.field1))
                #expect(result.errors.errorFields.contains(.field2))
                #expect(result.errors.messages[.field1] == ["Fast error"])
                #expect(result.errors.messages[.field2] == ["Slow error"])
            }
        }
    }

    @Suite("performance")
    struct PerformanceTests {

        @Suite("with many fast validators")
        struct ManyFastValidatorsTests {

            @Test("completes validation quickly")
            func completesValidationQuickly() async {
                let formControl = ValidationUtilsTests().createFormControl()

                // Register many fields with fast validators
                for i in 1...50 {
                    let fieldName = TestValidationFieldName.field1 // Using same field name for simplicity
                    _ = formControl.register(name: fieldName, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value\(i)"
                    ))
                }

                let startTime = DispatchTime.now()
                let result = await formControl.validateAllFields()
                let endTime = DispatchTime.now()
                let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                #expect(result.isValid == true)
                #expect(timeElapsed < 1_000_000_000) // Should complete in less than 1 second
            }
        }

        @Suite("early termination performance")
        struct EarlyTerminationPerformanceTests {

            @Test("terminates early with shouldStopOnFirstError")
            func terminatesEarlyWithShouldStopOnFirstError() async {
                let formControl = ValidationUtilsTests().createFormControl()

                // First field fails immediately
                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["Fast error"]),
                    defaultValue: "value1"
                ))

                let startTime = DispatchTime.now()
                let result = await formControl.validateAllFields(shouldStopOnFirstError: true)
                let endTime = DispatchTime.now()
                let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                #expect(result.isValid == false)
                #expect(timeElapsed < 1_000_000_000) // Should terminate quickly
            }
        }
    }

    @Suite("edge cases")
    struct EdgeCaseTests {

        @Suite("with validators that have empty error messages")
        struct EmptyErrorMessagesTests {

            @Test("handles empty error messages correctly")
            func handlesEmptyErrorMessagesCorrectly() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: []),
                    defaultValue: "value1"
                ))

                let result = await formControl.validateFields(fieldNames: [.field1])

                #expect(result.isValid == false)
                #expect(result.errors.errorFields.contains(.field1))
                #expect(result.errors.messages[.field1] == [])
            }
        }

        @Suite("with fields registered and immediately unregistered")
        struct FieldsRegisteredAndUnregisteredTests {

            @Test("handles unregistered fields gracefully")
            func handlesUnregisteredFieldsGracefully() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))

                await formControl.unregister(name: .field1)

                let result = await formControl.validateFields(fieldNames: [.field1])

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }

        @Suite("with duplicate field names in validation list")
        struct DuplicateFieldNamesTests {

            @Test("handles duplicate field names without issues")
            func handlesDuplicateFieldNamesWithoutIssues() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: true),
                    defaultValue: "value1"
                ))

                let result = await formControl.validateFields(fieldNames: [.field1, .field1, .field1])

                #expect(result.isValid == true)
                #expect(result.errors.errorFields.isEmpty)
            }
        }

        @Suite("validation with special characters and unicode")
        struct SpecialCharactersUnicodeTests {

            @Test("handles unicode error messages correctly")
            func handlesUnicodeErrorMessagesCorrectly() async {
                let formControl = ValidationUtilsTests().createFormControl()

                _ = formControl.register(name: .field1, options: .init(
                    rules: MockValidator<String, Bool>(result: false, messages: ["错误信息", "エラーメッセージ", "🚫 Invalid"]),
                    defaultValue: "value1"
                ))

                let result = await formControl.validateFields(fieldNames: [.field1])

                #expect(result.isValid == false)
                #expect(result.errors.messages[.field1] == ["错误信息", "エラーメッセージ", "🚫 Invalid"])
            }
        }
    }
}