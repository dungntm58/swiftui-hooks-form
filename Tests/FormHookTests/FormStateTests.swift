//
//  FormStateTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

@testable import FormHook
import Foundation
import Testing

enum TestStateFieldName: Hashable {
    case name
    case email
    case age
    case address
}

@Suite("FormState")
struct FormStateTests {

    @Suite("Initialization")
    struct InitializationTests {

        @Suite("with default values")
        struct DefaultValuesTests {

            @Test("initializes with correct default state")
            func initializesWithCorrectDefaultState() {
                let formState = FormState<TestStateFieldName>()

                #expect(formState.dirtyFields.isEmpty)
                #expect(formState.formValues.isEmpty)
                #expect(formState.defaultValues.isEmpty)
                #expect(formState.submissionState == .notSubmit)
                #expect(formState.isSubmitSuccessful == false)
                #expect(formState.submitCount == 0)
                #expect(formState.isValid == true)
                #expect(formState.isValidating == false)
                #expect(formState.errors.errorFields.isEmpty)
                #expect(formState.errors.messages.isEmpty)
            }
        }

        @Suite("with custom values")
        struct CustomValuesTests {

            @Test("initializes with provided values")
            func initializesWithProvidedValues() {
                let dirtyFields: Set<TestStateFieldName> = [.name, .email]
                let formValues: FormValue<TestStateFieldName> = [.name: "John", .email: "john@example.com"]
                let defaultValues: FormValue<TestStateFieldName> = [.name: "", .email: ""]
                let errors = FormError<TestStateFieldName>(
                    errorFields: [.email],
                    messages: [.email: ["Invalid email"]]
                )

                let formState = FormState<TestStateFieldName>(
                    dirtyFields: dirtyFields,
                    formValues: formValues,
                    defaultValues: defaultValues,
                    submissionState: .submitting,
                    isSubmitSuccessful: true,
                    submitCount: 2,
                    isValid: false,
                    isValidating: true,
                    errors: errors
                )

                #expect(formState.dirtyFields == dirtyFields)
                #expect(formState.formValues[.name] as? String == "John")
                #expect(formState.formValues[.email] as? String == "john@example.com")
                #expect(formState.defaultValues[.name] as? String == "")
                #expect(formState.defaultValues[.email] as? String == "")
                #expect(formState.submissionState == .submitting)
                #expect(formState.isSubmitSuccessful == true)
                #expect(formState.submitCount == 2)
                #expect(formState.isValid == false)
                #expect(formState.isValidating == true)
                #expect(formState.errors.errorFields.contains(.email))
                #expect(formState.errors.messages[.email] == ["Invalid email"])
            }
        }
    }

    @Suite("Mutation operations")
    struct MutationTests {

        @Suite("Dirty fields manipulation")
        struct DirtyFieldsTests {

            @Test("adds and removes dirty fields correctly")
            func addsAndRemovesDirtyFieldsCorrectly() {
                var formState = FormState<TestStateFieldName>()

                // Add dirty fields
                formState.dirtyFields.insert(.name)
                formState.dirtyFields.insert(.email)

                #expect(formState.dirtyFields.contains(.name))
                #expect(formState.dirtyFields.contains(.email))
                #expect(formState.dirtyFields.count == 2)

                // Remove dirty field
                formState.dirtyFields.remove(.name)

                #expect(!formState.dirtyFields.contains(.name))
                #expect(formState.dirtyFields.contains(.email))
                #expect(formState.dirtyFields.count == 1)
            }
        }

        @Suite("Form values manipulation")
        struct FormValuesTests {

            @Test("sets and gets form values correctly")
            func setsAndGetsFormValuesCorrectly() {
                var formState = FormState<TestStateFieldName>()

                // Set form values
                formState.formValues[.name] = "Alice"
                formState.formValues[.email] = "alice@example.com"
                formState.formValues[.age] = 25

                #expect(formState.formValues[.name] as? String == "Alice")
                #expect(formState.formValues[.email] as? String == "alice@example.com")
                #expect(formState.formValues[.age] as? Int == 25)

                // Update form value
                formState.formValues[.name] = "Alice Smith"
                #expect(formState.formValues[.name] as? String == "Alice Smith")

                // Remove form value
                formState.formValues.removeValue(forKey: .age)
                #expect(formState.formValues[.age] == nil)
            }
        }

        @Suite("Submission state changes")
        struct SubmissionStateTests {

            @Test("changes submission state correctly")
            func changesSubmissionStateCorrectly() {
                var formState = FormState<TestStateFieldName>()

                #expect(formState.submissionState == .notSubmit)

                formState.submissionState = .submitting
                #expect(formState.submissionState == .submitting)

                formState.submissionState = .submitted
                #expect(formState.submissionState == .submitted)
            }

            @Test("updates submit count and success state")
            func updatesSubmitCountAndSuccessState() {
                var formState = FormState<TestStateFieldName>()

                #expect(formState.submitCount == 0)
                #expect(formState.isSubmitSuccessful == false)

                formState.submitCount = 1
                formState.isSubmitSuccessful = true

                #expect(formState.submitCount == 1)
                #expect(formState.isSubmitSuccessful == true)
            }
        }

        @Suite("Validation state changes")
        struct ValidationStateTests {

            @Test("changes validation state correctly")
            func changesValidationStateCorrectly() {
                var formState = FormState<TestStateFieldName>()

                #expect(formState.isValid == true)
                #expect(formState.isValidating == false)

                formState.isValid = false
                formState.isValidating = true

                #expect(formState.isValid == false)
                #expect(formState.isValidating == true)
            }
        }
    }

    @Suite("Equality operations")
    struct EqualityTests {

        @Test("considers identical states equal")
        func considersIdenticalStatesEqual() {
            let formState1 = FormState<TestStateFieldName>(
                dirtyFields: [.name],
                formValues: [.name: "John"],
                defaultValues: [.name: ""],
                submissionState: .notSubmit,
                isSubmitSuccessful: false,
                submitCount: 0,
                isValid: true,
                isValidating: false,
                errors: FormError<TestStateFieldName>()
            )

            let formState2 = FormState<TestStateFieldName>(
                dirtyFields: [.name],
                formValues: [.name: "John"],
                defaultValues: [.name: ""],
                submissionState: .notSubmit,
                isSubmitSuccessful: false,
                submitCount: 0,
                isValid: true,
                isValidating: false,
                errors: FormError<TestStateFieldName>()
            )

            #expect(formState1 == formState2)
        }

        @Test("considers different states unequal")
        func considersDifferentStatesUnequal() {
            let formState1 = FormState<TestStateFieldName>(
                dirtyFields: [.name],
                formValues: [.name: "John"],
                defaultValues: [.name: ""],
                submissionState: .notSubmit,
                isSubmitSuccessful: false,
                submitCount: 0,
                isValid: true,
                isValidating: false,
                errors: FormError<TestStateFieldName>()
            )

            let formState2 = FormState<TestStateFieldName>(
                dirtyFields: [.email],  // Different dirty field
                formValues: [.name: "John"],
                defaultValues: [.name: ""],
                submissionState: .notSubmit,
                isSubmitSuccessful: false,
                submitCount: 0,
                isValid: true,
                isValidating: false,
                errors: FormError<TestStateFieldName>()
            )

            #expect(formState1 != formState2)
        }
    }
}

@Suite("FieldState")
struct FieldStateTests {

    @Suite("Initialization")
    struct InitializationTests {

        @Test("initializes with provided values")
        func initializesWithProvidedValues() {
            let fieldState = FieldState(isDirty: true, isInvalid: false, error: ["Test error"])

            #expect(fieldState.isDirty == true)
            #expect(fieldState.isInvalid == false)
            #expect(fieldState.error == ["Test error"])
        }

        @Test("initializes with default values")
        func initializesWithDefaultValues() {
            let fieldState = FieldState(isDirty: false, isInvalid: true, error: [])

            #expect(fieldState.isDirty == false)
            #expect(fieldState.isInvalid == true)
            #expect(fieldState.error.isEmpty)
        }
    }

    @Suite("State combinations")
    struct StateCombinationTests {

        @Test("can be dirty and invalid")
        func canBeDirtyAndInvalid() {
            let fieldState = FieldState(isDirty: true, isInvalid: true, error: ["Field is required"])

            #expect(fieldState.isDirty == true)
            #expect(fieldState.isInvalid == true)
            #expect(fieldState.error == ["Field is required"])
        }

        @Test("can be clean and valid")
        func canBeCleanAndValid() {
            let fieldState = FieldState(isDirty: false, isInvalid: false, error: [])

            #expect(fieldState.isDirty == false)
            #expect(fieldState.isInvalid == false)
            #expect(fieldState.error.isEmpty)
        }

        @Test("can have multiple error messages")
        func canHaveMultipleErrorMessages() {
            let fieldState = FieldState(
                isDirty: true,
                isInvalid: true,
                error: ["Field is required", "Must be at least 8 characters", "Must contain numbers"]
            )

            #expect(fieldState.isDirty == true)
            #expect(fieldState.isInvalid == true)
            #expect(fieldState.error.count == 3)
            #expect(fieldState.error.contains("Field is required"))
            #expect(fieldState.error.contains("Must be at least 8 characters"))
            #expect(fieldState.error.contains("Must contain numbers"))
        }
    }
}

@Suite("FormValue operations")
struct FormValueOperationTests {

    @Test("supports different value types")
    func supportsDifferentValueTypes() {
        var formValue: FormValue<TestStateFieldName> = [:]

        formValue[.name] = "John Doe"
        formValue[.email] = "john@example.com"
        formValue[.age] = 30

        #expect(formValue[.name] as? String == "John Doe")
        #expect(formValue[.email] as? String == "john@example.com")
        #expect(formValue[.age] as? Int == 30)
    }

    @Test("handles complex data types")
    func handlesComplexDataTypes() {
        var formValue: FormValue<TestStateFieldName> = [:]

        let addressDict = ["street": "123 Main St", "city": "Springfield", "zip": "12345"]
        formValue[.address] = addressDict

        let retrievedAddress = formValue[.address] as? [String: String]
        #expect(retrievedAddress?["street"] == "123 Main St")
        #expect(retrievedAddress?["city"] == "Springfield")
        #expect(retrievedAddress?["zip"] == "12345")
    }

    @Test("supports nil values")
    func supportsNilValues() {
        var formValue: FormValue<TestStateFieldName> = [:]

        formValue[.name] = "John"
        #expect(formValue[.name] as? String == "John")

        formValue[.name] = nil
        #expect(formValue[.name] == nil)
    }
}

@Suite("FormError operations")
struct FormErrorOperationTests {

    @Suite("Initialization")
    struct InitializationTests {

        @Test("initializes with empty state")
        func initializesWithEmptyState() {
            let formError = FormError<TestStateFieldName>()

            #expect(formError.errorFields.isEmpty)
            #expect(formError.messages.isEmpty)
        }

        @Test("initializes with provided errors")
        func initializesWithProvidedErrors() {
            let errorFields: Set<TestStateFieldName> = [.name, .email]
            let messages: [TestStateFieldName: [String]] = [
                .name: ["Name is required"],
                .email: ["Invalid email format"]
            ]

            let formError = FormError<TestStateFieldName>(
                errorFields: errorFields,
                messages: messages
            )

            #expect(formError.errorFields == errorFields)
            #expect(formError.messages[.name] == ["Name is required"])
            #expect(formError.messages[.email] == ["Invalid email format"])
        }
    }

    @Suite("Error manipulation")
    struct ErrorManipulationTests {

        @Test("creates and accesses errors correctly")
        func createsAndAccessesErrorsCorrectly() {
            // Test FormError initialization with data
            let formError = FormError<TestStateFieldName>(
                errorFields: [.name],
                messages: [.name: ["Name is required"]]
            )

            #expect(formError.errorFields.contains(.name))
            #expect(formError.messages[.name] == ["Name is required"])

            // Test subscript access
            #expect(formError[.name] == ["Name is required"])
            #expect(formError[.email] == []) // Non-existent field returns empty array
        }

        @Test("handles multiple errors for single field")
        func handlesMultipleErrorsForSingleField() {
            let formError = FormError<TestStateFieldName>(
                errorFields: [.email],
                messages: [.email: ["Email is required", "Invalid email format", "Email already taken"]]
            )

            #expect(formError.errorFields.contains(.email))
            #expect(formError.messages[.email]?.count == 3)
            #expect(formError.messages[.email]?.contains("Email is required") == true)
            #expect(formError.messages[.email]?.contains("Invalid email format") == true)
            #expect(formError.messages[.email]?.contains("Email already taken") == true)
        }
    }

    @Suite("Subscript access")
    struct SubscriptAccessTests {

        @Test("provides subscript access to error messages")
        func providesSubscriptAccessToErrorMessages() {
            let formError = FormError<TestStateFieldName>(
                errorFields: [.name, .email],
                messages: [
                    .name: ["Name is required"],
                    .email: ["Invalid email format", "Email too long"]
                ]
            )

            #expect(formError[.name] == ["Name is required"])
            #expect(formError[.email] == ["Invalid email format", "Email too long"])
            #expect(formError[.age] == [])  // Non-existent field returns empty array
        }
    }

    @Suite("Union operations")
    struct UnionOperationTests {

        @Test("combines two form errors correctly")
        func combinesTwoFormErrorsCorrectly() {
            let error1 = FormError<TestStateFieldName>(
                errorFields: [.name],
                messages: [.name: ["Name is required"]]
            )

            let error2 = FormError<TestStateFieldName>(
                errorFields: [.email],
                messages: [.email: ["Invalid email"]]
            )

            let combinedError = error1.union(error2)

            #expect(combinedError.errorFields.contains(.name))
            #expect(combinedError.errorFields.contains(.email))
            #expect(combinedError.messages[.name] == ["Name is required"])
            #expect(combinedError.messages[.email] == ["Invalid email"])
        }

        @Test("merges overlapping error messages")
        func mergesOverlappingErrorMessages() {
            let error1 = FormError<TestStateFieldName>(
                errorFields: [.email],
                messages: [.email: ["Email is required"]]
            )

            let error2 = FormError<TestStateFieldName>(
                errorFields: [.email],
                messages: [.email: ["Invalid email format"]]
            )

            let combinedError = error1.union(error2)

            #expect(combinedError.errorFields.contains(.email))
            #expect(combinedError.messages[.email]?.count == 2)
            #expect(combinedError.messages[.email]?.contains("Email is required") == true)
            #expect(combinedError.messages[.email]?.contains("Invalid email format") == true)
        }
    }

    @Suite("Basic operations")
    struct BasicOperationTests {

        @Test("creates error with multiple fields")
        func createsErrorWithMultipleFields() {
            let formError = FormError<TestStateFieldName>(
                errorFields: [.name, .email, .age],
                messages: [
                    .name: ["Name is required"],
                    .email: ["Invalid email"],
                    .age: ["Age must be positive"]
                ]
            )

            #expect(formError.errorFields.contains(.name))
            #expect(formError.errorFields.contains(.email))
            #expect(formError.errorFields.contains(.age))
            #expect(formError.messages[.name] == ["Name is required"])
            #expect(formError.messages[.email] == ["Invalid email"])
            #expect(formError.messages[.age] == ["Age must be positive"])
        }

        @Test("checks equality of error fields and messages")
        func checksEqualityOfErrorFieldsAndMessages() {
            let error1 = FormError<TestStateFieldName>(
                errorFields: [.name],
                messages: [.name: ["Name is required"]]
            )

            let error2 = FormError<TestStateFieldName>(
                errorFields: [.name],
                messages: [.name: ["Name is required"]]
            )

            #expect(error1.errorFields == error2.errorFields)
            #expect(error1.messages == error2.messages)
        }
    }
}
