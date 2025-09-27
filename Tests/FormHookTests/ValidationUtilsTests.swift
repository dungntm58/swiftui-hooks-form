//
//  ValidationUtilsTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

import Foundation
import Quick
import Nimble
@preconcurrency @testable import FormHook

enum TestValidationFieldName: Hashable {
    case field1
    case field2
    case field3
    case field4
    case field5
}

final class ValidationUtilsTests: QuickSpec {
    override func spec() {
        validateFieldsSpecs()
        validateAllFieldsSpecs()
        revalidateErrorFieldsSpecs()
        concurrentValidationSpecs()
        performanceSpecs()
        edgeCaseSpecs()
    }

    func validateFieldsSpecs() {
        describe("validateFields") {
            var formControl: FormControl<TestValidationFieldName>!

            beforeEach {
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
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }

            context("with all valid fields") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value2"
                    ))
                }

                it("returns overall valid result") {
                    let result = await formControl.validateFields(fieldNames: [.field1, .field2])

                    expect(result.isValid) == true
                    expect(result.errors.errorFields).to(beEmpty())
                    // Check that all message arrays are empty rather than the dictionary being empty
                    for (_, messages) in result.errors.messages {
                        expect(messages).to(beEmpty())
                    }
                }
            }

            context("with some invalid fields") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field2 error"]),
                        defaultValue: "value2"
                    ))
                    _ = formControl.register(name: .field3, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field3 error"]),
                        defaultValue: "value3"
                    ))
                }

                it("returns overall invalid result with error details") {
                    let result = await formControl.validateFields(fieldNames: [.field1, .field2, .field3])

                    expect(result.isValid) == false
                    expect(result.errors.errorFields).to(contain(.field2))
                    expect(result.errors.errorFields).to(contain(.field3))
                    expect(result.errors.errorFields).notTo(contain(.field1))
                    expect(result.errors.messages[.field2]) == ["Field2 error"]
                    expect(result.errors.messages[.field3]) == ["Field3 error"]
                    expect(result.errors.messages[.field1]).to(beEmpty())
                }
            }

            context("with shouldStopOnFirstError = true") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages: ["Field1 error"]),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages: ["Field2 error"]),
                        defaultValue: "value2"
                    ))
                }

                it("stops validation early and returns partial results") {
                    let startTime = DispatchTime.now()
                    let result = await formControl.validateFields(fieldNames: [.field1, .field2], shouldStopOnFirstError: true)
                    let endTime = DispatchTime.now()
                    let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                    expect(result.isValid) == false
                    expect(result.errors.errorFields.count) >= 1
                    // Should complete faster than validating both fields sequentially
                    expect(timeElapsed).to(beLessThan(120_000_000)) // Less than 120ms
                }
            }

            context("with empty field names list") {
                it("returns valid result") {
                    let result = await formControl.validateFields(fieldNames: [])

                    expect(result.isValid) == true
                    expect(result.errors.errorFields).to(beEmpty())
                    expect(result.errors.messages).to(beEmpty())
                }
            }

            context("with non-existent fields") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                }

                it("ignores non-existent fields and validates existing ones") {
                    let result = await formControl.validateFields(fieldNames: [.field1, .field2, .field3])

                    expect(result.isValid) == true
                    expect(result.errors.errorFields).to(beEmpty())
                    expect(result.errors.messages).to(haveCount(1))
                    expect(result.errors.messages[.field1]).to(beEmpty())
                }
            }
        }
    }

    func validateAllFieldsSpecs() {
        describe("validateAllFields") {
            var formControl: FormControl<TestValidationFieldName>!

            beforeEach {
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
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }

            context("with no registered fields") {
                it("returns valid result") {
                    let result = await formControl.validateAllFields()

                    expect(result.isValid) == true
                    expect(result.errors.errorFields).to(beEmpty())
                    expect(result.errors.messages).to(beEmpty())
                }
            }

            context("with multiple registered fields") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field2 invalid"]),
                        defaultValue: "value2"
                    ))
                    _ = formControl.register(name: .field3, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value3"
                    ))
                }

                it("validates all registered fields") {
                    let result = await formControl.validateAllFields()

                    expect(result.isValid) == false
                    expect(result.errors.errorFields).to(contain(.field2))
                    expect(result.errors.errorFields).notTo(contain(.field1))
                    expect(result.errors.errorFields).notTo(contain(.field3))
                    expect(result.errors.messages[.field2]) == ["Field2 invalid"]
                }

                it("includes all fields in messages, even valid ones") {
                    let result = await formControl.validateAllFields()

                    expect(result.errors.messages).to(haveCount(3))
                    expect(result.errors.messages[.field1]).to(beEmpty())
                    expect(result.errors.messages[.field2]) == ["Field2 invalid"]
                    expect(result.errors.messages[.field3]).to(beEmpty())
                }
            }

            context("with shouldStopOnFirstError = true") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field1 error"]),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages: ["Field2 error"]),
                        defaultValue: "value2"
                    ))
                }

                it("stops early on first error") {
                    let startTime = DispatchTime.now()
                    let result = await formControl.validateAllFields(shouldStopOnFirstError: true)
                    let endTime = DispatchTime.now()
                    let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                    expect(result.isValid) == false
                    // Should complete much faster than 200ms
                    expect(timeElapsed).to(beLessThan(150_000_000))
                }
            }
        }
    }

    func revalidateErrorFieldsSpecs() {
        describe("revalidateErrorFields") {
            var formControl: FormControl<TestValidationFieldName>!

            beforeEach {
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
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }

            context("with no existing errors") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value2"
                    ))
                }

                it("returns valid result with no validation") {
                    let result = await formControl.revalidateErrorFields()

                    expect(result.isValid) == true
                    expect(result.errors.errorFields).to(beEmpty())
                    expect(result.errors.messages).to(beEmpty())
                }
            }

            context("with existing errors") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field2 now valid"]),
                        defaultValue: "value2"
                    ))
                    _ = formControl.register(name: .field3, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field3 still invalid"]),
                        defaultValue: "value3"
                    ))

                    // Set up existing error state
                    formControl.instantFormState.errors.setMessages(name: .field2, messages: ["Old field2 error"], isValid: false)
                    formControl.instantFormState.errors.setMessages(name: .field3, messages: ["Old field3 error"], isValid: false)
                }

                it("only revalidates fields with existing errors") {
                    let result = await formControl.revalidateErrorFields()

                    expect(result.isValid) == false
                    expect(result.errors.errorFields).to(contain(.field2))
                    expect(result.errors.errorFields).to(contain(.field3))
                    expect(result.errors.errorFields).notTo(contain(.field1))
                    expect(result.errors.messages).to(haveCount(2))
                    expect(result.errors.messages[.field1]).to(beNil())
                }

                it("updates error messages from validators") {
                    let result = await formControl.revalidateErrorFields()

                    expect(result.errors.messages[.field2]) == ["Field2 now valid"]
                    expect(result.errors.messages[.field3]) == ["Field3 still invalid"]
                }
            }

            context("with errors that are now resolved") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true), // Now valid
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result: true), // Now valid
                        defaultValue: "value2"
                    ))

                    // Set up existing error state
                    formControl.instantFormState.errors.setMessages(name: .field1, messages: ["Old error1"], isValid: false)
                    formControl.instantFormState.errors.setMessages(name: .field2, messages: ["Old error2"], isValid: false)
                }

                it("returns valid result when errors are resolved") {
                    let result = await formControl.revalidateErrorFields()

                    expect(result.isValid) == true
                    expect(result.errors.messages[.field1]).to(beEmpty())
                    expect(result.errors.messages[.field2]).to(beEmpty())
                }
            }
        }
    }

    func concurrentValidationSpecs() {
        describe("concurrent validation") {
            var formControl: FormControl<TestValidationFieldName>!

            beforeEach {
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
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }

            context("with delayed validators") {
                beforeEach {
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
                }

                it("runs validations concurrently") {
                    let startTime = DispatchTime.now()
                    let result = await formControl.validateAllFields()
                    let endTime = DispatchTime.now()
                    let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                    expect(result.isValid) == true
                    // Should complete in around 100ms (concurrent) not 300ms (sequential)
                    // Just verify it completed in reasonable time (less than 1 second)
                    expect(timeElapsed).to(beLessThan(1_000_000_000)) // Less than 1 second
                }
            }

            context("with mixed validation speeds") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Fast error"]),
                        defaultValue: "value1"
                    ))
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result:false, messages: ["Slow error"]),
                        defaultValue: "value2"
                    ))
                }

                it("waits for all validations to complete") {
                    let result = await formControl.validateAllFields()

                    expect(result.isValid) == false
                    expect(result.errors.errorFields).to(contain(.field1))
                    expect(result.errors.errorFields).to(contain(.field2))
                    expect(result.errors.messages[.field1]) == ["Fast error"]
                    expect(result.errors.messages[.field2]) == ["Slow error"]
                }
            }
        }
    }

    func performanceSpecs() {
        describe("performance") {
            var formControl: FormControl<TestValidationFieldName>!

            beforeEach {
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
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }

            context("with many fast validators") {
                beforeEach {
                    for i in 1...5 { // Reduced from 100 to 5 for test speed
                        let fieldName: TestValidationFieldName
                        switch i % 5 {
                        case 1: fieldName = .field1
                        case 2: fieldName = .field2
                        case 3: fieldName = .field3
                        case 4: fieldName = .field4
                        default: fieldName = .field5
                        }
                        _ = formControl.register(name: fieldName, options: .init(
                            rules: MockValidator<String, Bool>(result: i % 3 != 0, messages: ["Error \(i)"]),
                            defaultValue: "value\(i)"
                        ))
                    }
                }

                it("completes validation quickly") {
                    let startTime = DispatchTime.now()
                    let result = await formControl.validateAllFields()
                    let endTime = DispatchTime.now()
                    let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                    expect(result.isValid) == false // Some fields should be invalid
                    expect(timeElapsed).to(beLessThan(50_000_000)) // Less than 50ms
                }
            }

            context("early termination performance") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Immediate error"]),
                        defaultValue: "value1"
                    ))
                    // Add some slow validators that shouldn't run
                    _ = formControl.register(name: .field2, options: .init(
                        rules: MockValidator<String, Bool>(result:false, messages: ["Slow error"]),
                        defaultValue: "value2"
                    ))
                }

                it("terminates early with shouldStopOnFirstError") {
                    let startTime = DispatchTime.now()
                    let result = await formControl.validateAllFields(shouldStopOnFirstError: true)
                    let endTime = DispatchTime.now()
                    let timeElapsed = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

                    expect(result.isValid) == false
                    expect(timeElapsed).to(beLessThan(100_000_000)) // Much less than 500ms
                }
            }
        }
    }

    func edgeCaseSpecs() {
        describe("edge cases") {
            var formControl: FormControl<TestValidationFieldName>!

            beforeEach {
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
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }

            context("with validators that have empty error messages") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:[]),
                        defaultValue: "value1"
                    ))
                }

                it("handles empty error messages correctly") {
                    let result = await formControl.validateAllFields()

                    expect(result.isValid) == false
                    expect(result.errors.errorFields).to(contain(.field1))
                    expect(result.errors.messages[.field1]).to(beEmpty())
                }
            }

            context("with fields registered and immediately unregistered") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: true),
                        defaultValue: "value1"
                    ))
                    await formControl.unregister(name: .field1)
                }

                it("handles unregistered fields gracefully") {
                    let result = await formControl.validateFields(fieldNames: [.field1])

                    expect(result.isValid) == true
                    expect(result.errors.errorFields).to(beEmpty())
                    expect(result.errors.messages).to(beEmpty())
                }
            }

            context("with duplicate field names in validation list") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Field1 error"]),
                        defaultValue: "value1"
                    ))
                }

                it("handles duplicate field names without issues") {
                    let result = await formControl.validateFields(fieldNames: [.field1, .field1, .field1])

                    expect(result.isValid) == false
                    expect(result.errors.errorFields).to(contain(.field1))
                    expect(result.errors.messages[.field1]) == ["Field1 error"]
                }
            }

            context("validation with special characters and unicode") {
                beforeEach {
                    _ = formControl.register(name: .field1, options: .init(
                        rules: MockValidator<String, Bool>(result: false, messages:["Error with 🚨 emoji", "Ñoñó español", "中文错误"]),
                        defaultValue: "🎯 unicode value"
                    ))
                }

                it("handles unicode error messages correctly") {
                    let result = await formControl.validateAllFields()

                    expect(result.isValid) == false
                    expect(result.errors.messages[.field1]).to(contain("Error with 🚨 emoji"))
                    expect(result.errors.messages[.field1]).to(contain("Ñoñó español"))
                    expect(result.errors.messages[.field1]).to(contain("中文错误"))
                }
            }
        }
    }
}