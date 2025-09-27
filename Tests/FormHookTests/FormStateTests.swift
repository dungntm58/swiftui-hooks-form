//
//  FormStateTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

import Foundation
import Quick
import Nimble
@testable import FormHook

enum TestStateFieldName: Hashable {
    case name
    case email
    case age
    case address
}

final class FormStateTests: QuickSpec {
    override func spec() {
        formStateInitializationSpecs()
        formStateMutationSpecs()
        formStateEqualitySpecs()
        fieldStateSpecs()
        formValueOperationsSpecs()
        formErrorOperationsSpecs()
    }

    func formStateInitializationSpecs() {
        describe("FormState initialization") {
            context("with default values") {
                var formState: FormState<TestStateFieldName>!

                beforeEach {
                    formState = FormState<TestStateFieldName>()
                }

                it("initializes with correct default state") {
                    expect(formState.dirtyFields).to(beEmpty())
                    expect(formState.formValues).to(beEmpty())
                    expect(formState.defaultValues).to(beEmpty())
                    expect(formState.submissionState) == .notSubmit
                    expect(formState.isSubmitSuccessful) == false
                    expect(formState.submitCount) == 0
                    expect(formState.isValid) == true
                    expect(formState.isValidating) == false
                    expect(formState.errors.errorFields).to(beEmpty())
                    expect(formState.errors.messages).to(beEmpty())
                }

                it("isDirty returns false for empty dirty fields") {
                    expect(formState.isDirty) == false
                }
            }

            context("with custom initial values") {
                var formState: FormState<TestStateFieldName>!

                beforeEach {
                    formState = FormState<TestStateFieldName>(
                        dirtyFields: [.name, .email],
                        formValues: [.name: "John", .email: "john@example.com"],
                        defaultValues: [.name: "", .email: ""],
                        submissionState: .submitted,
                        isSubmitSuccessful: true,
                        submitCount: 1,
                        isValid: false,
                        isValidating: true,
                        errors: FormError(
                            errorFields: [.email],
                            messages: [.email: ["Invalid email"]]
                        )
                    )
                }

                it("initializes with provided values") {
                    expect(formState.dirtyFields) == Set([.name, .email])
                    expect(formState.formValues[.name] as? String) == "John"
                    expect(formState.formValues[.email] as? String) == "john@example.com"
                    expect(formState.defaultValues[.name] as? String) == ""
                    expect(formState.defaultValues[.email] as? String) == ""
                    expect(formState.submissionState) == .submitted
                    expect(formState.isSubmitSuccessful) == true
                    expect(formState.submitCount) == 1
                    expect(formState.isValid) == false
                    expect(formState.isValidating) == true
                    expect(formState.errors.errorFields) == Set([.email])
                    expect(formState.errors.messages[.email]) == ["Invalid email"]
                }

                it("isDirty returns true for non-empty dirty fields") {
                    expect(formState.isDirty) == true
                }
            }
        }
    }

    func formStateMutationSpecs() {
        describe("FormState mutations") {
            var formState: FormState<TestStateFieldName>!

            beforeEach {
                formState = FormState<TestStateFieldName>()
            }

            context("modifying dirty fields") {
                it("can add dirty fields") {
                    formState.dirtyFields.insert(.name)
                    formState.dirtyFields.insert(.email)

                    expect(formState.dirtyFields) == Set([.name, .email])
                    expect(formState.isDirty) == true
                }

                it("can remove dirty fields") {
                    formState.dirtyFields = Set([.name, .email, .age])
                    formState.dirtyFields.remove(.email)

                    expect(formState.dirtyFields) == Set([.name, .age])
                    expect(formState.isDirty) == true
                }

                it("isDirty becomes false when all dirty fields removed") {
                    formState.dirtyFields = Set([.name])
                    formState.dirtyFields.remove(.name)

                    expect(formState.dirtyFields).to(beEmpty())
                    expect(formState.isDirty) == false
                }
            }

            context("modifying form values") {
                it("can set and get form values") {
                    formState.formValues[.name] = "John Doe"
                    formState.formValues[.age] = 30

                    expect(formState.formValues[.name] as? String) == "John Doe"
                    expect(formState.formValues[.age] as? Int) == 30
                }

                it("can remove form values") {
                    formState.formValues[.name] = "John"
                    formState.formValues[.name] = nil

                    expect(formState.formValues[.name]).to(beNil())
                }

                it("handles various data types") {
                    formState.formValues[.name] = "String"
                    formState.formValues[.age] = 25
                    formState.formValues[.email] = true
                    formState.formValues[.address] = [1, 2, 3]

                    expect(formState.formValues[.name] as? String) == "String"
                    expect(formState.formValues[.age] as? Int) == 25
                    expect(formState.formValues[.email] as? Bool) == true
                    expect(formState.formValues[.address] as? [Int]) == [1, 2, 3]
                }
            }

            context("modifying submission state") {
                it("can change submission state") {
                    formState.submissionState = .submitting
                    expect(formState.submissionState) == .submitting

                    formState.submissionState = .submitted
                    expect(formState.submissionState) == .submitted

                    formState.submissionState = .notSubmit
                    expect(formState.submissionState) == .notSubmit
                }

                it("can update submit success status") {
                    formState.isSubmitSuccessful = true
                    expect(formState.isSubmitSuccessful) == true

                    formState.isSubmitSuccessful = false
                    expect(formState.isSubmitSuccessful) == false
                }

                it("can increment submit count") {
                    formState.submitCount = 5
                    expect(formState.submitCount) == 5

                    formState.submitCount += 1
                    expect(formState.submitCount) == 6
                }
            }

            context("modifying validation state") {
                it("can change validation status") {
                    formState.isValid = false
                    expect(formState.isValid) == false

                    formState.isValid = true
                    expect(formState.isValid) == true
                }

                it("can change validating status") {
                    formState.isValidating = true
                    expect(formState.isValidating) == true

                    formState.isValidating = false
                    expect(formState.isValidating) == false
                }
            }
        }
    }

    func formStateEqualitySpecs() {
        describe("FormState equality") {
            var formState1: FormState<TestStateFieldName>!
            var formState2: FormState<TestStateFieldName>!

            beforeEach {
                formState1 = FormState<TestStateFieldName>(
                    dirtyFields: [.name],
                    formValues: [.name: "John"],
                    defaultValues: [.name: ""],
                    submissionState: .notSubmit,
                    isSubmitSuccessful: false,
                    submitCount: 0,
                    isValid: true,
                    isValidating: false,
                    errors: FormError()
                )

                formState2 = FormState<TestStateFieldName>(
                    dirtyFields: [.name],
                    formValues: [.name: "John"],
                    defaultValues: [.name: ""],
                    submissionState: .notSubmit,
                    isSubmitSuccessful: false,
                    submitCount: 0,
                    isValid: true,
                    isValidating: false,
                    errors: FormError()
                )
            }

            it("considers identical states equal") {
                expect(formState1) == formState2
            }

            it("considers states with different dirty fields unequal") {
                formState2.dirtyFields = [.email]
                expect(formState1) != formState2
            }

            it("considers states with different form values unequal") {
                formState2.formValues[.name] = "Jane"
                expect(formState1) != formState2
            }

            it("considers states with different default values unequal") {
                formState2.defaultValues[.name] = "Default"
                expect(formState1) != formState2
            }

            it("considers states with different submission states unequal") {
                formState2.submissionState = .submitted
                expect(formState1) != formState2
            }

            it("considers states with different submit success unequal") {
                formState2.isSubmitSuccessful = true
                expect(formState1) != formState2
            }

            it("considers states with different submit counts unequal") {
                formState2.submitCount = 1
                expect(formState1) != formState2
            }

            it("considers states with different validity unequal") {
                formState2.isValid = false
                expect(formState1) != formState2
            }

            it("considers states with different validating status unequal") {
                formState2.isValidating = true
                expect(formState1) != formState2
            }

            it("considers states with different errors unequal") {
                formState2.errors = FormError(
                    errorFields: [.email],
                    messages: [.email: ["Error"]]
                )
                expect(formState1) != formState2
            }
        }
    }

    func fieldStateSpecs() {
        describe("FieldState") {
            var formState: FormState<TestStateFieldName>!

            beforeEach {
                formState = FormState<TestStateFieldName>(
                    dirtyFields: [.name, .email],
                    formValues: [.name: "John", .email: "invalid-email"],
                    defaultValues: [.name: "", .email: ""],
                    errors: FormError(
                        errorFields: [.email],
                        messages: [.email: ["Invalid email format"]]
                    )
                )
            }

            context("for dirty valid field") {
                it("returns correct field state") {
                    let fieldState = formState.getFieldState(name: .name)

                    expect(fieldState.isDirty) == true
                    expect(fieldState.isInvalid) == false
                    expect(fieldState.error).to(beEmpty())
                }
            }

            context("for dirty invalid field") {
                it("returns correct field state") {
                    let fieldState = formState.getFieldState(name: .email)

                    expect(fieldState.isDirty) == true
                    expect(fieldState.isInvalid) == true
                    expect(fieldState.error) == ["Invalid email format"]
                }
            }

            context("for clean valid field") {
                it("returns correct field state") {
                    let fieldState = formState.getFieldState(name: .age)

                    expect(fieldState.isDirty) == false
                    expect(fieldState.isInvalid) == false
                    expect(fieldState.error).to(beEmpty())
                }
            }

            context("for field with multiple errors") {
                beforeEach {
                    formState.errors = FormError(
                        errorFields: [.name],
                        messages: [.name: ["Required", "Too short", "Invalid characters"]]
                    )
                }

                it("returns all error messages") {
                    let fieldState = formState.getFieldState(name: .name)

                    expect(fieldState.isDirty) == true
                    expect(fieldState.isInvalid) == true
                    expect(fieldState.error) == ["Required", "Too short", "Invalid characters"]
                }
            }
        }
    }

    func formValueOperationsSpecs() {
        describe("FormValue operations") {
            var formValue1: FormValue<TestStateFieldName>!
            var formValue2: FormValue<TestStateFieldName>!

            beforeEach {
                formValue1 = [.name: "John", .email: "john@example.com"]
                formValue2 = [.age: 30, .address: "123 Main St"]
            }

            context("union operation") {
                it("merges two form values") {
                    formValue1.unioned(formValue2)

                    expect(formValue1[.name] as? String) == "John"
                    expect(formValue1[.email] as? String) == "john@example.com"
                    expect(formValue1[.age] as? Int) == 30
                    expect(formValue1[.address] as? String) == "123 Main St"
                }

                it("overwrites existing keys") {
                    formValue2[.name] = "Jane"
                    formValue1.unioned(formValue2)

                    expect(formValue1[.name] as? String) == "Jane"
                    expect(formValue1[.email] as? String) == "john@example.com"
                }

                it("handles empty form values") {
                    let emptyFormValue: FormValue<TestStateFieldName> = [:]
                    formValue1.unioned(emptyFormValue)

                    expect(formValue1[.name] as? String) == "John"
                    expect(formValue1[.email] as? String) == "john@example.com"
                }

                it("handles union with self") {
                    formValue1.unioned(formValue1)

                    expect(formValue1[.name] as? String) == "John"
                    expect(formValue1[.email] as? String) == "john@example.com"
                }
            }
        }
    }

    func formErrorOperationsSpecs() {
        describe("FormError operations") {
            var formError: FormError<TestStateFieldName>!

            beforeEach {
                formError = FormError<TestStateFieldName>()
            }

            context("setting messages") {
                it("sets valid field messages") {
                    formError.setMessages(name: .name, messages: nil, isValid: true)

                    expect(formError.errorFields).notTo(contain(.name))
                    expect(formError.messages[.name]).to(beNil())
                    expect(formError[.name]).to(beNil())
                }

                it("sets invalid field messages") {
                    formError.setMessages(name: .email, messages: ["Invalid format"], isValid: false)

                    expect(formError.errorFields).to(contain(.email))
                    expect(formError.messages[.email]) == ["Invalid format"]
                    expect(formError[.email]) == ["Invalid format"]
                }

                it("updates existing field messages") {
                    formError.setMessages(name: .name, messages: ["Error 1"], isValid: false)
                    formError.setMessages(name: .name, messages: ["Error 2"], isValid: false)

                    expect(formError.errorFields).to(contain(.name))
                    expect(formError[.name]) == ["Error 2"]
                }
            }

            context("removing errors") {
                beforeEach {
                    formError.setMessages(name: .name, messages: ["Name error"], isValid: false)
                    formError.setMessages(name: .email, messages: ["Email error"], isValid: false)
                }

                it("removes field completely") {
                    formError.remove(name: .name)

                    expect(formError.errorFields).notTo(contain(.name))
                    expect(formError.messages[.name]).to(beNil())
                    expect(formError.errorFields).to(contain(.email))
                }

                it("removes messages only") {
                    formError.removeMessagesOnly(name: .name)

                    expect(formError.errorFields).to(contain(.name))
                    expect(formError.messages[.name]).to(beNil())
                }

                it("removes validity only") {
                    formError.removeValidityOnly(name: .name)

                    expect(formError.errorFields).notTo(contain(.name))
                    expect(formError.messages[.name]) == ["Name error"]
                }
            }

            context("union operations") {
                var otherError: FormError<TestStateFieldName>!

                beforeEach {
                    formError.setMessages(name: .name, messages: ["Name error"], isValid: false)

                    otherError = FormError<TestStateFieldName>()
                    otherError.setMessages(name: .email, messages: ["Email error"], isValid: false)
                    otherError.setMessages(name: .age, messages: ["Age error"], isValid: false)
                }

                it("combines error fields and messages") {
                    let unionError = formError.union(otherError)

                    expect(unionError.errorFields).to(contain(.name))
                    expect(unionError.errorFields).to(contain(.email))
                    expect(unionError.errorFields).to(contain(.age))
                    expect(unionError[.name]) == ["Name error"]
                    expect(unionError[.email]) == ["Email error"]
                    expect(unionError[.age]) == ["Age error"]
                }

                it("overwrites existing messages") {
                    otherError.setMessages(name: .name, messages: ["Updated name error"], isValid: false)
                    let unionError = formError.union(otherError)

                    expect(unionError[.name]) == ["Updated name error"]
                }

                it("handles empty error union") {
                    let emptyError = FormError<TestStateFieldName>()
                    let unionError = formError.union(emptyError)

                    expect(unionError.errorFields) == formError.errorFields
                    expect(unionError.messages) == formError.messages
                }
            }

            context("error conformance") {
                it("conforms to Error protocol") {
                    let error: Error = formError
                    expect(error).to(beAKindOf(FormError<TestStateFieldName>.self))
                }
            }
        }
    }
}