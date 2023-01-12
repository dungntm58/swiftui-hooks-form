import SwiftUI
import Quick
import Nimble

@testable import FormHook

enum TestFieldName: String {
    case a
    case b
}

final class FormHookTests: QuickSpec {
    override func spec() {
        registerSpecs()
        unregisterSpecs()
        resetSingleFieldSpecs()
        resetFormSpecs()
        clearErrorsSpecs()
        setValueSpecs()
        handleSubmitSpecs()
        triggerSpecs()
        resolverSpecs()
        changeFieldValueSpecs()
    }
    
    func registerSpecs() {
        describe("Form Control") {
            var formControl: FormControl<TestFieldName>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
            }
            
            context("registers a field \"a\" with a default value") {
                var aValidator: MockValidator<String, Bool>!
                let testDefaultValue = "%^$#"
                let testDefaultValue2 = "%^$#@"
                var aBinder: FieldRegistration<String>!
                
                beforeEach {
                    aValidator = MockValidator<String, Bool>(result: true)
                    aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
                }
                
                context("value for key \"a\" changes") {
                    beforeEach {
                        aBinder.wrappedValue = "a"
                        await formControl.syncFormState()
                    }
                    
                    context("registers field \"a\" with the same options") {
                        beforeEach {
                            aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
                            await formControl.syncFormState()
                        }
                        
                        it("field \"a\" changes its default value, and doesn't change its value") {
                            let formState = await formControl.formState
                            expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue)) == true
                            expect(areEqual(first: formState.formValues[.a], second: "a")) == true
                        }
                    }
                    
                    context("registers field \"a\" with other options") {
                        beforeEach {
                            aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue2))
                            await formControl.syncFormState()
                        }
                        
                        it("field \"a\" changes its default value, and doesn't change its value") {
                            let formState = await formControl.formState
                            expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue2)) == true
                            expect(areEqual(first: formState.formValues[.a], second: "a")) == true
                        }
                    }
                    
                    it("key \"a\" and formState are dirty") {
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isDirty) == true
                        
                        let formState = await formControl.formState
                        expect(formState.isDirty) == true
                    }
                }
                
                context("registers field \"a\" with other options") {
                    beforeEach {
                        aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue2))
                        await formControl.syncFormState()
                    }
                    
                    it("field \"a\" changes its value") {
                        let formState = await formControl.formState
                        expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue2)) == true
                        expect(areEqual(first: formState.formValues[.a], second: testDefaultValue2)) == true
                    }
                }
            }
        }
    }
    
    func unregisterSpecs() {
        describe("Form Control with shouldUnregister equals false registers a field \"a\" with a default value") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            let testDefaultValue = "%^$#"
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: false,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
            }
            
            context("then unregister field \"a\"") {
                context("key \"a\" hasn't been configured") {
                    beforeEach {
                        await formControl.unregister(name: .a)
                    }
                    
                    it("value of key \"a\" will be removed") {
                        let formState = await formControl.formState
                        expect(formState.defaultValues[.a]).to(beNil())
                        expect(formState.formValues[.a]).to(beNil())
                    }
                }
            }
        }
        
        describe("Form Control registers a field \"a\" with a default value") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            let testDefaultValue = "%^$#"
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
            }
            
            it("value of key a equals the default value") {
                expect(areEqual(first: formControl.instantFormState.formValues[.a], second: testDefaultValue)) == true
                expect(areEqual(first: formControl.instantFormState.defaultValues[.a], second: testDefaultValue)) == true
            }
            
            context("then unregister field \"a\"") {
                context("with no option") {
                    context("key \"a\" hasn't been configured") {
                        beforeEach {
                            await formControl.unregister(name: .a)
                        }
                        
                        it("value of key \"a\" will be removed") {
                            let formState = await formControl.formState
                            expect(formState.formValues[.a]).to(beNil())
                        }
                    }
                    
                    context("key \"a\" has been already dirty") {
                        beforeEach {
                            formControl.instantFormState.dirtyFields.insert(.a)
                            await formControl.syncFormState()
                            await formControl.unregister(name: .a)
                        }
                        
                        it("field \"a\" is not dirty") {
                            let isDirty = formControl.getFieldState(name: .a).isDirty
                            expect(isDirty) == false
                        }
                    }
                }
                
                context("with option .keepValue") {
                    beforeEach {
                        await formControl.unregister(name: .a, options: .keepValue)
                    }
                    
                    it("value of key \"a\" remains") {
                        let formState = formControl.instantFormState
                        expect(areEqual(first: formState.formValues[.a], second: testDefaultValue)) == true
                    }
                }
                
                context("with option .keepDefaultValue") {
                    beforeEach {
                        await formControl.unregister(name: .a, options: .keepDefaultValue)
                    }
                    
                    it("default value of key \"a\" remains") {
                        let formState = formControl.instantFormState
                        expect(formState.formValues[.a]).to(beNil())
                        expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue)) == true
                    }
                }
                
                context("with option .keepDirty") {
                    context("key \"a\" hasn't been already dirty") {
                        beforeEach {
                            await formControl.unregister(name: .a, options: .keepDirty)
                        }
                        
                        it("dirtyness of \"a\" remains") {
                            let isDirty = await formControl.getFieldState(name: .a).isDirty
                            expect(isDirty) == false
                        }
                    }
                    
                    context("key \"a\" has been already dirty") {
                        beforeEach {
                            formControl.instantFormState.dirtyFields.insert(.a)
                            await formControl.syncFormState()
                            await formControl.unregister(name: .a, options: .keepDirty)
                        }
                        
                        it("dirtyness of \"a\" remains") {
                            let isDirty = await formControl.getFieldState(name: .a).isDirty
                            expect(isDirty) == true
                        }
                    }
                }
                
                context("with option .keepIsValid") {
                    context("key \"a\" hasn't been already invalid") {
                        beforeEach {
                            aValidator.result = false
                            await formControl.unregister(name: .a, options: .keepIsValid)
                        }
                        
                        it("validity of key \"a\" remains") {
                            let isInvalid = await formControl.getFieldState(name: .a).isInvalid
                            expect(isInvalid) == false
                        }
                    }
                    
                    context("key \"a\" has been already invalid") {
                        beforeEach {
                            aValidator.result = false
                            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                            await formControl.syncFormState()
                            await formControl.unregister(name: .a, options: .keepIsValid)
                        }
                        
                        it("validity of \"a\" remains") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isInvalid) == true
                            expect(fieldState.error).to(beEmpty())
                        }
                    }
                }
                
                context("with option .keepError") {
                    context("key \"a\" hasn't been already invalid") {
                        beforeEach {
                            aValidator.result = false
                            await formControl.unregister(name: .a, options: .keepError)
                        }
                        
                        it("key \"a\" remains errors") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isInvalid) == false
                            expect(fieldState.error).to(beEmpty())
                        }
                    }
                    
                    context("key \"a\" has been already invalid") {
                        beforeEach {
                            aValidator.result = false
                            formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                            await formControl.syncFormState()
                            await formControl.unregister(name: .a, options: .keepError)
                        }
                        
                        it("key \"a\" remains errors") {
                            let fieldState = formControl.getFieldState(name: .a)
                            expect(fieldState.isInvalid) == false
                            expect(fieldState.error.count) == 1
                            expect(fieldState.error.first) == "Failed to validate a"
                        }
                    }
                }
            }
        }
    }
    
    func resetSingleFieldSpecs() {
        describe("Form Control registered field \"a\" and \"b\" with non-nil resolver") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            var bValidator: MockValidator<String, Bool>!
            let aDefaultValue = "%^$#"
            let bDefaultValue = "%^$#*("
            
            let resolverProxy = ResolverProxy<TestFieldName>(value: [
                .a: aDefaultValue,
                .b: bDefaultValue
            ])
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: resolverProxy.resolver(values:context:fieldNames:),
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: aDefaultValue))
                
                bValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .b, options: .init(rules: bValidator!, defaultValue: bDefaultValue))
            }
            
            context("formState is invalid, key \"a\" has been already invalid") {
                beforeEach {
                    formControl.instantFormState.isValid = false
                    formControl.instantFormState.errors.setMessages(
                        name: .a,
                        messages: [
                            "Failed to validate a"
                        ],
                        isValid: false
                    )
                    await formControl.syncFormState()
                }
                
                context("reset field \"b\" with default option") {
                    beforeEach {
                        await formControl.reset(name: .b)
                    }
                    
                    it("field \"a\" is still invalid") {
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == true
                        expect(fieldState.error) == ["Failed to validate a"]
                    }
                }
            }
        }
        
        describe("Form Control registered field \"a\"") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            let testDefaultValue = "%^$#"
            let testDefaultValue2 = "%^$#*("
            var aBinder: FieldRegistration<String>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
            }
            
            context("controller of field \"a\" changes its value to \"abc\"") {
                beforeEach {
                    aBinder.wrappedValue = "abc"
                    await formControl.syncFormState()
                }
                
                it("value of \"a\" equals \"abc\"") {
                    let formState = await formControl.formState
                    expect(areEqual(first: formState.formValues[.a], second: "abc")) == true
                }
                
                it("field \"a\" is dirty") {
                    let fieldState = await formControl.getFieldState(name: .a)
                    expect(fieldState.isDirty) == true
                }
                
                context("reset field \"a\"") {
                    context("with no option") {
                        beforeEach {
                            await formControl.reset(name: .a)
                        }
                        
                        it("value of field \"a\" changes to the original default value") {
                            let formState = await formControl.formState
                            expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue)) == true
                            expect(areEqual(first: formState.formValues[.a], second: testDefaultValue)) == true
                        }
                        
                        it("key \"a\" is not dirty") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isDirty) == false
                        }
                        
                        context("with another default value") {
                            beforeEach {
                                await formControl.reset(name: .a, defaultValue: testDefaultValue2)
                            }
                            
                            it("value of field \"a\" changes to the new default value") {
                                let formState = await formControl.formState
                                expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue2)) == true
                                expect(areEqual(first: formState.formValues[.a], second: testDefaultValue2)) == true
                            }
                        }
                    }
                    
                    context("with option .keepDirty") {
                        beforeEach {
                            await formControl.reset(name: .a, options: .keepDirty)
                        }
                        
                        it("dirtyness of \"a\" remains") {
                            let isDirty = await formControl.getFieldState(name: .a).isDirty
                            expect(isDirty) == true
                        }
                    }
                    
                    context("with option .keepError") {
                        context("key \"a\" hasn't been already invalid") {
                            beforeEach {
                                aValidator.result = false
                                await formControl.reset(name: .a, options: .keepError)
                            }
                            
                            it("key \"a\" remains errors") {
                                let fieldState = await formControl.getFieldState(name: .a)
                                expect(fieldState.isInvalid) == false
                                expect(fieldState.error).to(beEmpty())
                            }
                        }
                        
                        context("key \"a\" has been already invalid") {
                            beforeEach {
                                formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                                await formControl.syncFormState()
                                await formControl.reset(name: .a, options: .keepError)
                            }
                            
                            it("key \"a\" remains errors") {
                                let fieldState = await formControl.getFieldState(name: .a)
                                expect(fieldState.isInvalid) == true
                                expect(fieldState.error.count) == 1
                                expect(fieldState.error.first) == "Failed to validate a"
                            }
                        }
                    }
                    
                    context("with another default value") {
                        beforeEach {
                            await formControl.reset(name: .a, defaultValue: testDefaultValue2)
                        }
                        
                        it("default value of field \"a\" changes to new value") {
                            let formState = await formControl.formState
                            expect(areEqual(first: formState.defaultValues[.a], second: testDefaultValue2)) == true
                            expect(areEqual(first: formState.formValues[.a], second: testDefaultValue2)) == true
                        }
                    }
                }
            }
        }
    }
    
    func resetFormSpecs() {
        describe("Form Control registered field \"a\" and \"b\"") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            var bValidator: MockValidator<String, Bool>!
            let aDefaultValue = "%^$#"
            let bDefaultValue = "%^$#*("
            
            let aDefaultValue2 = "%^$#)"
            let bDefaultValue2 = "%^$#*()"
            
            var aBinder: FieldRegistration<String>!
            var bBinder: FieldRegistration<String>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: aDefaultValue))
                
                bValidator = MockValidator<String, Bool>(result: true)
                bBinder = formControl.register(name: .b, options: .init(rules: bValidator!, defaultValue: bDefaultValue))
            }
            
            context("reset with no options") {
                context("and formState is not submitted") {
                    beforeEach {
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ])
                    }
                    
                    it("default values of key \"a\" and \"b\" change to new default values") {
                        let formState = await formControl.formState
                        expect(areEqual(first: formState.defaultValues[.a], second: aDefaultValue2)) == true
                        expect(areEqual(first: formState.defaultValues[.b], second: bDefaultValue2)) == true
                    }
                    
                    it("values of key \"a\" and \"b\" change to new default values") {
                        let formState = await formControl.formState
                        expect(areEqual(first: formState.formValues[.a], second: aDefaultValue2)) == true
                        expect(areEqual(first: formState.formValues[.b], second: bDefaultValue2)) == true
                    }
                    
                    it("key \"a\" and \"b\" are not dirty") {
                        let aFieldState = await formControl.getFieldState(name: .a)
                        expect(aFieldState.isDirty) == false
                        
                        let bFieldState = await formControl.getFieldState(name: .b)
                        expect(bFieldState.isDirty) == false
                    }
                }
                
                context("and formState is submitted") {
                    beforeEach {
                        formControl.instantFormState.submitCount = 1
                        formControl.instantFormState.submissionState = .submitted
                        formControl.instantFormState.isSubmitSuccessful = true
                        
                        await formControl.syncFormState()
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ])
                    }
                    
                    it("submitCount equals 0") {
                        let formState = await formControl.formState
                        expect(formState.submitCount) == 0
                    }
                    
                    it("formState isSubmitted is false") {
                        let formState = await formControl.formState
                        expect(formState.submissionState) == .notSubmit
                        expect(formState.isSubmitSuccessful) == false
                    }
                }
            }
            
            context("reset with option .keepDefaultValues") {
                beforeEach {
                    await formControl.reset(defaultValues: [
                        .a: aDefaultValue2,
                        .b: bDefaultValue2
                    ], options: .keepDefaultValues)
                }
                
                it("default values of key \"a\" and \"b\" don't change") {
                    let formState = await formControl.formState
                    expect(areEqual(first: formState.defaultValues[.a], second: aDefaultValue)) == true
                    expect(areEqual(first: formState.defaultValues[.b], second: bDefaultValue)) == true
                }
                
                it("values of key \"a\" and \"b\" change to new default values") {
                    let formState = await formControl.formState
                    expect(areEqual(first: formState.formValues[.a], second: aDefaultValue2)) == true
                    expect(areEqual(first: formState.formValues[.b], second: bDefaultValue2)) == true
                }
            }
            
            context("reset with option .keepValues") {
                beforeEach {
                    await formControl.reset(defaultValues: [
                        .a: aDefaultValue2,
                        .b: bDefaultValue2
                    ], options: .keepValues)
                }
                
                it("default values of key \"a\" and \"b\" change to new default values") {
                    let formState = await formControl.formState
                    expect(areEqual(first: formState.defaultValues[.a], second: aDefaultValue2)) == true
                    expect(areEqual(first: formState.defaultValues[.b], second: bDefaultValue2)) == true
                }
                
                it("values of key \"a\" and \"b\" don't change") {
                    let formState = await formControl.formState
                    expect(areEqual(first: formState.formValues[.a], second: aDefaultValue)) == true
                    expect(areEqual(first: formState.formValues[.b], second: bDefaultValue)) == true
                }
            }
            
            context("reset with option .keepDirty") {
                context("values of \"a\" and \"b\" change") {
                    beforeEach {
                        aBinder.wrappedValue = "new value a"
                        bBinder.wrappedValue = "new value b"
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepDirty)
                    }
                    
                    it("key \"a\" and \"b\" are still dirty") {
                        let aFieldState = await formControl.getFieldState(name: .a)
                        expect(aFieldState.isDirty) == true
                        
                        let bFieldState = await formControl.getFieldState(name: .b)
                        expect(bFieldState.isDirty) == true
                    }
                }
                
                context("values of \"a\" changes and \"b\" doesn't") {
                    beforeEach {
                        aBinder.wrappedValue = "new value a"
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepDirty)
                    }
                    
                    it("key \"a\" is dirty and \"b\" isn't") {
                        let aFieldState = await formControl.getFieldState(name: .a)
                        expect(aFieldState.isDirty) == true
                        
                        let bFieldState = await formControl.getFieldState(name: .b)
                        expect(bFieldState.isDirty) == false
                    }
                }
                
                context("values of \"a\" and \"b\" don't change") {
                    beforeEach {
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepDirty)
                    }
                    
                    it("key \"a\" and \"b\" aren't dirty") {
                        let aFieldState = await formControl.getFieldState(name: .a)
                        expect(aFieldState.isDirty) == false
                        
                        let bFieldState = await formControl.getFieldState(name: .b)
                        expect(bFieldState.isDirty) == false
                    }
                }
            }
            
            context("reset with option .keepErrors") {
                context("key \"a\" has been already invalid") {
                    beforeEach {
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                        formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                        formControl.instantFormState.isValid = false
                        await formControl.syncFormState()
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepErrors)
                    }
                    
                    it("key \"a\" remains errors") {
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == true
                        expect(fieldState.error.count) == 1
                        expect(fieldState.error.first) == "Failed to validate a"
                    }
                    
                    it("key \"b\" remains errors") {
                        let fieldState = await formControl.getFieldState(name: .b)
                        expect(fieldState.isInvalid) == false
                        expect(fieldState.error).to(beEmpty())
                    }
                }
                
                context("key \"a\" and \"b\" have been already invalid") {
                    beforeEach {
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                        bValidator.result = false
                        bValidator.messages = ["Failed to validate b"]
                        formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                        formControl.instantFormState.errors.setMessages(name: .b, messages: ["Failed to validate b"], isValid: false)
                        formControl.instantFormState.isValid = false
                        await formControl.syncFormState()
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepErrors)
                    }
                    
                    it("key \"b\" remains errors") {
                        let fieldState = await formControl.getFieldState(name: .b)
                        expect(fieldState.isInvalid) == true
                        expect(fieldState.error.count) == 1
                        expect(fieldState.error.first) == "Failed to validate b"
                    }
                }
            }
            
            context("reset with option .keepIsValid") {
                context("and formState isn't valid") {
                    beforeEach {
                        formControl.instantFormState.isValid = false
                        
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                        
                        await formControl.syncFormState()
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepIsValid)
                    }
                    
                    it("formState validity remains") {
                        let formState = await formControl.formState
                        expect(formState.isValid) == false
                    }
                }
            }
            
            context("reset with option .keepSubmitCount") {
                context("and submitCount equals 1") {
                    beforeEach {
                        formControl.instantFormState.submitCount = 1
                        
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                        
                        await formControl.syncFormState()
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepSubmitCount)
                    }
                    
                    it("submitCount equals 1") {
                        let formState = await formControl.formState
                        expect(formState.submitCount) == 1
                    }
                }
            }
            
            context("reset with option .keepIsSubmitted") {
                context("and form is submitted") {
                    beforeEach {
                        formControl.instantFormState.submitCount = 1
                        formControl.instantFormState.submissionState = .submitted
                        formControl.instantFormState.isSubmitSuccessful = true
                        
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                        
                        await formControl.syncFormState()
                        await formControl.reset(defaultValues: [
                            .a: aDefaultValue2,
                            .b: bDefaultValue2
                        ], options: .keepIsSubmitted)
                    }
                    
                    it("formState isSubmitted is true") {
                        let formState = await formControl.formState
                        expect(formState.submissionState) == .submitted
                    }
                }
            }
        }
    }
    
    func clearErrorsSpecs() {
        describe("Form Control registered field \"a\" and \"b\"") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            var bValidator: MockValidator<String, Bool>!
            let aDefaultValue = "%^$#"
            let bDefaultValue = "%^$#*("
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: aDefaultValue))
                
                bValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .b, options: .init(rules: bValidator!, defaultValue: bDefaultValue))
            }
            
            context("key \"a\" and \"b\" have been already invalid and will be failed for validation") {
                beforeEach {
                    aValidator.result = false
                    aValidator.messages = ["Failed to validate a"]
                    bValidator.result = false
                    bValidator.messages = ["Failed to validate b"]
                    formControl.instantFormState.errors.setMessages(name: .a, messages: ["Failed to validate a"], isValid: false)
                    formControl.instantFormState.errors.setMessages(name: .b, messages: ["Failed to validate b"], isValid: false)
                    formControl.instantFormState.isValid = false
                    await formControl.syncFormState()
                }
                
                context("clear errors of field \"a\"") {
                    beforeEach {
                        await formControl.clearErrors(name: .a)
                    }
                    
                    it("errors of key \"a\" has gone") {
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == false
                        expect(fieldState.error).to(beEmpty())
                    }
                    
                    it("key \"b\" remains errors") {
                        let fieldState = await formControl.getFieldState(name: .b)
                        expect(fieldState.isInvalid) == true
                        expect(fieldState.error.count) == 1
                        expect(fieldState.error.first) == "Failed to validate b"
                    }
                }
            }
        }
    }
    
    func setValueSpecs() {
        describe("Form Control registers a field \"a\" with a default value") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            let testDefaultValue = "%^$#"
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
            }
            
            context("set a value for key \"a\"") {
                context("with a value other than default value (%%%)") {
                    context("with no option") {
                        beforeEach {
                            await formControl.setValue(name: .a, value: "%%%")
                        }
                        
                        it("key \"a\" is dirty") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isDirty) == true
                        }
                        
                        it("key \"a\" changes its value") {
                            let formState = await formControl.formState
                            expect(areEqual(first: formState.formValues[.a], second: "%%%")) == true
                        }
                    }
                    
                    context("with option .shouldDirty") {
                        beforeEach {
                            await formControl.setValue(name: .a, value: "%%%", options: .shouldDirty)
                        }
                        
                        it("key \"a\" is dirty") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isDirty) == true
                        }
                    }
                }
                
                context("with a value other than default value") {
                    context("with no option") {
                        beforeEach {
                            await formControl.setValue(name: .a, value: testDefaultValue)
                        }
                        
                        it("key \"a\" isn't dirty") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isDirty) == false
                        }
                    }
                    
                    context("with option .shouldDirty") {
                        beforeEach {
                            await formControl.setValue(name: .a, value: testDefaultValue, options: .shouldDirty)
                        }
                        
                        it("key \"a\" is dirty") {
                            let fieldState = await formControl.getFieldState(name: .a)
                            expect(fieldState.isDirty) == true
                        }
                    }
                    
                    context("with option .shouldValidate") {
                        context("validator returns false") {
                            beforeEach {
                                aValidator.result = false
                                await formControl.setValue(name: .a, value: testDefaultValue, options: .shouldValidate)
                            }
                            
                            it("key \"a\" is invalid") {
                                let fieldState = await formControl.getFieldState(name: .a)
                                expect(fieldState.isInvalid) == true
                            }
                            
                            it("formState is invalid") {
                                let formState = await formControl.formState
                                expect(formState.isValid) == false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func handleSubmitSpecs() {
        describe("Form Control registered field \"a\" and \"b\"") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            var bValidator: MockValidator<String, Bool>!
            let aDefaultValue = "%^$#"
            let bDefaultValue = "%^$#*("
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: aDefaultValue))
                
                bValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .b, options: .init(rules: bValidator!, defaultValue: bDefaultValue))
            }
            
            context("with mode .onSubmit") {
                context("invoke handleSubmit action") {
                    it("submitCount is 1, isSubmitSuccessful is true, and submissionState is .submitted") {
                        do {
                            try await formControl.handleSubmit(onValid: { _, _ in })
                            let formState = await formControl.formState
                            expect(formState.submitCount) == 1
                            expect(formState.isSubmitSuccessful) == true
                            expect(formState.submissionState) == .submitted
                        } catch {
                            fail()
                        }
                    }
                    
                    context("key \"a\" is invalid") {
                        beforeEach {
                            aValidator.result = false
                            aValidator.messages = ["Failed to validate a"]
                        }
                        
                        context("delayError equals 100ms") {
                            beforeEach {
                                formControl.options.delayErrorInNanoseconds = 100_000_000
                            }
                            
                            it("formState accepts errors after 100ms") {
                                do {
                                    try await formControl.handleSubmit(onValid: { _, _ in })
                                    let formState = await formControl.formState
                                    expect(formState.errors.errorFields.isEmpty) == true
                                    
                                    try await Task.sleep(nanoseconds: 110_000_000)
                                    let fieldState = await formControl.getFieldState(name: .a)
                                    expect(fieldState.isInvalid) == true
                                    expect(fieldState.error) == ["Failed to validate a"]
                                } catch {
                                    fail()
                                }
                            }
                        }
                        
                        it("formState is invalid") {
                            do {
                                try await formControl.handleSubmit(onValid: { _, _ in })
                                let formState = await formControl.formState
                                expect(formState.isValid) == false
                                expect(formState.errors[.a]) == ["Failed to validate a"]
                                expect(formState.errors[.b]).to(beEmpty())
                            } catch {
                                fail()
                            }
                        }
                        
                        it("submitCount is 1, isSubmitSuccessful is false, and submissionState is .submitted") {
                            do {
                                try await formControl.handleSubmit(onValid: { _, _ in })
                                let formState = await formControl.formState
                                expect(formState.submitCount) == 1
                                expect(formState.isSubmitSuccessful) == false
                                expect(formState.submissionState) == .submitted
                            } catch {
                                fail()
                            }
                        }
                        
                        context("key \"b\" is invalid") {
                            beforeEach {
                                bValidator.result = false
                                bValidator.messages = ["Failed to validate b"]
                            }
                            
                            it("formState is still invalid") {
                                do {
                                    try await formControl.handleSubmit(onValid: { _, _ in })
                                    let formState = await formControl.formState
                                    expect(formState.isValid) == false
                                    expect(formState.errors[.a]) == ["Failed to validate a"]
                                    expect(formState.errors[.b]) == ["Failed to validate b"]
                                } catch {
                                    fail()
                                }
                            }
                        }
                    }
                }
                
                context("invoke handleSubmit action with onValid closure throws an error and onInvalid closure is nil") {
                    it("submitCount is 1, isSubmitSuccessful is false, and submissionState is .submitted") {
                        do {
                            try await formControl.handleSubmit(onValid: { _, _ in
                                throw NSError(domain: "", code: 999)
                            })
                            fail()
                        } catch {
                            let formState = await formControl.formState
                            expect(formState.submitCount) == 1
                            expect(formState.isSubmitSuccessful) == false
                            expect(formState.submissionState) == .submitted
                        }
                    }
                    
                    context("key \"a\" is invalid") {
                        beforeEach {
                            aValidator.result = false
                            aValidator.messages = ["Failed to validate a"]
                        }
                        
                        it("formState is invalid") {
                            do {
                                try await formControl.handleSubmit(onValid: { _, _ in
                                    throw NSError(domain: "", code: 999)
                                })
                                let formState = await formControl.formState
                                expect(formState.isValid) == false
                                expect(formState.errors[.a]) == ["Failed to validate a"]
                                expect(formState.errors[.b]).to(beEmpty())
                            } catch {
                                fail()
                            }
                        }
                    }
                }
                
                context("invoke handleSubmit action with onInvalid closure throws an error") {
                    context("key \"a\" is invalid") {
                        beforeEach {
                            aValidator.result = false
                            aValidator.messages = ["Failed to validate a"]
                        }
                        
                        context("delayError equals 100ms") {
                            beforeEach {
                                formControl.options.delayErrorInNanoseconds = 100_000_000
                            }
                            
                            it("formState accepts errors after 100ms") {
                                do {
                                    try await formControl.handleSubmit { _, _ in
                                        
                                    } onInvalid: { _, _ in
                                        throw NSError(domain: "", code: 999)
                                    }
                                    fail()
                                } catch {
                                    let formState = await formControl.formState
                                    expect(formState.errors.errorFields.isEmpty) == true
                                    
                                    try await Task.sleep(nanoseconds: 110_000_000)
                                    let fieldState = await formControl.getFieldState(name: .a)
                                    expect(fieldState.isInvalid) == true
                                    expect(fieldState.error) == ["Failed to validate a"]
                                }
                            }
                        }
                        
                        it("formState is invalid") {
                            do {
                                try await formControl.handleSubmit { _, _ in
                                    
                                } onInvalid: { _, _ in
                                    throw NSError(domain: "", code: 999)
                                }
                                fail()
                            } catch {
                                let formState = await formControl.formState
                                expect(formState.isValid) == false
                                expect(formState.errors[.a]) == ["Failed to validate a"]
                                expect(formState.errors[.b]).to(beEmpty())
                            }
                        }
                    }
                }
            }
            
            context("with mode .onChange") {
                beforeEach {
                    formControl.options.mode = .onChange
                }
                
                context("with reValidateMode .onSubmit") {
                    beforeEach {
                        formControl.options.reValidateMode = .onSubmit
                    }
                    
                    context("invoke handleSubmit action") {
                        it("submitCount is 1, isSubmitSuccessful is true, and submissionState is .submitted") {
                            do {
                                try await formControl.handleSubmit(onValid: { _, _ in })
                                let formState = await formControl.formState
                                expect(formState.submitCount) == 1
                                expect(formState.isSubmitSuccessful) == true
                                expect(formState.submissionState) == .submitted
                            } catch {
                                fail()
                            }
                        }
                        
                        context("formState has been valid") {
                            context("key \"a\" is invalid") {
                                beforeEach {
                                    aValidator.result = false
                                    aValidator.messages = ["Failed to validate a"]
                                }
                                
                                it("formState is still valid") {
                                    do {
                                        try await formControl.handleSubmit(onValid: { _, _ in })
                                        let formState = await formControl.formState
                                        expect(formState.isValid) == true
                                        expect(formState.errors[.a]).to(beNil())
                                        expect(formState.errors[.b]).to(beNil())
                                    } catch {
                                        fail()
                                    }
                                }
                                
                                it("submitCount is 1, isSubmitSuccessful is true, and submissionState is .submitted") {
                                    do {
                                        try await formControl.handleSubmit(onValid: { _, _ in })
                                        let formState = await formControl.formState
                                        expect(formState.submitCount) == 1
                                        expect(formState.isSubmitSuccessful) == true
                                        expect(formState.submissionState) == .submitted
                                    } catch {
                                        fail()
                                    }
                                }
                                
                                context("key \"b\" is invalid") {
                                    beforeEach {
                                        bValidator.result = false
                                        bValidator.messages = ["Failed to validate b"]
                                    }
                                    
                                    it("formState is still valid") {
                                        do {
                                            try await formControl.handleSubmit(onValid: { _, _ in })
                                            let formState = await formControl.formState
                                            expect(formState.isValid) == true
                                            expect(formState.errors[.a]).to(beNil())
                                            expect(formState.errors[.b]).to(beNil())
                                        } catch {
                                            fail()
                                        }
                                    }
                                }
                            }
                        }
                        
                        context("formState has been invalid") {
                            beforeEach {
                                formControl.instantFormState.errors.setMessages(
                                    name: .a,
                                    messages: [
                                        "Failed to validate a"
                                    ],
                                    isValid: false)
                                await formControl.syncFormState()
                            }
                            
                            context("key \"a\" is invalid") {
                                beforeEach {
                                    aValidator.result = false
                                    aValidator.messages = ["Failed to validate a"]
                                }
                                
                                it("formState is invalid") {
                                    do {
                                        try await formControl.handleSubmit(onValid: { _, _ in })
                                        let formState = await formControl.formState
                                        expect(formState.isValid) == false
                                        expect(formState.errors[.a]) == ["Failed to validate a"]
                                        expect(formState.errors[.b]).to(beNil())
                                    } catch {
                                        fail()
                                    }
                                }
                                
                                it("submitCount is 1, isSubmitSuccessful is false, and submissionState is .submitted") {
                                    do {
                                        try await formControl.handleSubmit(onValid: { _, _ in })
                                        let formState = await formControl.formState
                                        expect(formState.submitCount) == 1
                                        expect(formState.isSubmitSuccessful) == false
                                        expect(formState.submissionState) == .submitted
                                    } catch {
                                        fail()
                                    }
                                }
                                
                                context("key \"b\" is invalid") {
                                    beforeEach {
                                        bValidator.result = false
                                        bValidator.messages = ["Failed to validate b"]
                                    }
                                    
                                    it("formState is still invalid") {
                                        do {
                                            try await formControl.handleSubmit(onValid: { _, _ in })
                                            let formState = await formControl.formState
                                            expect(formState.isValid) == false
                                            expect(formState.errors[.a]) == ["Failed to validate a"]
                                            expect(formState.errors[.b]).to(beNil())
                                        } catch {
                                            fail()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    context("invoke handleSubmit action with onValid closure throws an error and onInvalid closure is nil") {
                        it("submitCount is 1, isSubmitSuccessful is false, and submissionState is .submitted") {
                            do {
                                try await formControl.handleSubmit(onValid: { _, _ in
                                    throw NSError(domain: "", code: 999)
                                })
                                fail()
                            } catch {
                                let formState = await formControl.formState
                                expect(formState.submitCount) == 1
                                expect(formState.isSubmitSuccessful) == false
                                expect(formState.submissionState) == .submitted
                            }
                        }
                        
                        context("key \"a\" is invalid") {
                            beforeEach {
                                aValidator.result = false
                                aValidator.messages = ["Failed to validate a"]
                            }
                            
                            it("formState is still valid") {
                                do {
                                    try await formControl.handleSubmit(onValid: { _, _ in
                                        throw NSError(domain: "", code: 999)
                                    })
                                    fail()
                                } catch {
                                    let formState = await formControl.formState
                                    expect(formState.isValid) == true
                                    expect(formState.errors[.a]).to(beNil())
                                    expect(formState.errors[.b]).to(beNil())
                                }
                            }
                        }
                    }
                    
                    context("invoke handleSubmit action with onInvalid closure throws an error") {
                        context("key \"a\" is invalid") {
                            beforeEach {
                                aValidator.result = false
                                aValidator.messages = ["Failed to validate a"]
                            }
                            
                            it("formState is still valid") { // cause state of field a isn't getting any error
                                do {
                                    try await formControl.handleSubmit { _, _ in
                                        
                                    } onInvalid: { _, _ in
                                        throw NSError(domain: "", code: 999)
                                    }
                                    let formState = await formControl.formState
                                    expect(formState.isValid) == true
                                    expect(formState.errors[.a]).to(beNil())
                                    expect(formState.errors[.b]).to(beNil())
                                } catch {
                                    fail()
                                }
                            }
                        }
                    }
                }
                
                context("with reValidationMode .onChange") {
                    beforeEach {
                        formControl.options.reValidateMode = .onChange
                    }
                    
                    context("invoke handleSubmit action") {
                        context("key \"a\" is invalid") {
                            beforeEach {
                                aValidator.result = false
                                aValidator.messages = ["Failed to validate a"]
                            }
                            
                            it("formState is still valid") {
                                do {
                                    try await formControl.handleSubmit(onValid: { _, _ in })
                                    let formState = await formControl.formState
                                    expect(formState.isValid) == true
                                    expect(formState.errors[.a]).to(beNil())
                                    expect(formState.errors[.b]).to(beNil())
                                } catch {
                                    fail()
                                }
                            }
                            
                            it("submitCount is 1, isSubmitSuccessful is true, and submissionState is .submitted") {
                                do {
                                    try await formControl.handleSubmit(onValid: { _, _ in })
                                    let formState = await formControl.formState
                                    expect(formState.submitCount) == 1
                                    expect(formState.isSubmitSuccessful) == true
                                    expect(formState.submissionState) == .submitted
                                } catch {
                                    fail()
                                }
                            }
                        }
                    }
                    
                    context("invoke handleSubmit action with onInvalid closure throws an error and errors has been empty before") {
                        context("key \"a\" is invalid") {
                            beforeEach {
                                aValidator.result = false
                                aValidator.messages = ["Failed to validate a"]
                            }
                            
                            it("formState is invalid") {
                                do {
                                    try await formControl.handleSubmit { _, _ in
                                        
                                    } onInvalid: { _, _ in
                                        throw NSError(domain: "", code: 999)
                                    }
                                    let formState = await formControl.formState
                                    expect(formState.isValid) == true
                                    expect(formState.errors[.a]).to(beNil())
                                    expect(formState.errors[.b]).to(beNil())
                                } catch {
                                    fail()
                                }
                            }
                            
                            it("submitCount is 1, isSubmitSuccessful is true, and submissionState is .submitted") {
                                do {
                                    try await formControl.handleSubmit { _, _ in
                                        
                                    } onInvalid: { _, _ in
                                        throw NSError(domain: "", code: 999)
                                    }
                                    let formState = await formControl.formState
                                    expect(formState.submitCount) == 1
                                    expect(formState.isSubmitSuccessful) == true
                                    expect(formState.submissionState) == .submitted
                                } catch {
                                    fail()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func triggerSpecs() {
        describe("Form Control registered field \"a\" and \"b\"") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            var bValidator: MockValidator<String, Bool>!
            let aDefaultValue = "%^$#"
            let bDefaultValue = "%^$#*("
            var aBinder: FieldRegistration<String>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: aDefaultValue))
                
                bValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .b, options: .init(rules: bValidator!, defaultValue: bDefaultValue))
            }
            
            context("trigger field \"a\" and validation of \"a\" returns false") {
                beforeEach {
                    aValidator.result = false
                    aValidator.messages = ["Failed to validate a"]
                }
                
                context("delayError equals 100ms") {
                    beforeEach {
                        formControl.options.delayErrorInNanoseconds = 100_000_000
                    }
                    
                    it("formState accepts errors after 100ms") {
                        await formControl.trigger()
                        
                        let formState = await formControl.formState
                        expect(formState.errors.errorFields.isEmpty) == true
                        
                        try await Task.sleep(nanoseconds: 110_000_000)
                        let afieldState = await formControl.getFieldState(name: .a)
                        expect(afieldState.isInvalid) == true
                        expect(afieldState.error) == ["Failed to validate a"]
                        
                        let bfieldState = await formControl.getFieldState(name: .b)
                        expect(bfieldState.isInvalid) == false
                        expect(bfieldState.error).to(beEmpty())
                    }
                }
                
                it("result of validation \"a\" is false, and errors of \"a\" equals [\"Failed to validate a\"]") {
                    let result = await formControl.trigger(name: .a)
                    expect(result) == false
                    
                    let fieldState = await formControl.getFieldState(name: .a)
                    expect(fieldState.isInvalid) == true
                    expect(fieldState.error) == ["Failed to validate a"]
                }
                
                it("key \"b\" is still valid") {
                    await formControl.trigger(name: .a)
                    
                    let fieldState = await formControl.getFieldState(name: .b)
                    expect(fieldState.isInvalid) == false
                    expect(fieldState.error).to(beEmpty())
                }
            }
            
            context("trigger by default and validation of \"a\" returns false") {
                beforeEach {
                    aValidator.result = false
                    aValidator.messages = ["Failed to validate a"]
                }
                
                context("delayError equals 100ms") {
                    beforeEach {
                        formControl.options.delayErrorInNanoseconds = 100_000_000
                    }
                    
                    it("formState accepts errors after 100ms") {
                        await formControl.trigger()
                        
                        let formState = await formControl.formState
                        expect(formState.errors.errorFields.isEmpty) == true
                        
                        try await Task.sleep(nanoseconds: 110_000_000)
                        let afieldState = await formControl.getFieldState(name: .a)
                        expect(afieldState.isInvalid) == true
                        expect(afieldState.error) == ["Failed to validate a"]
                        
                        let bfieldState = await formControl.getFieldState(name: .b)
                        expect(bfieldState.isInvalid) == false
                        expect(bfieldState.error).to(beEmpty())
                    }
                }
                
                it("result of validation \"a\" is false, and errors of \"a\" equals [\"Failed to validate a\"]") {
                    let result = await formControl.trigger()
                    expect(result) == false
                    
                    let fieldState = await formControl.getFieldState(name: .a)
                    expect(fieldState.isInvalid) == true
                    expect(fieldState.error) == ["Failed to validate a"]
                }
                
                it("key \"b\" is still valid") {
                    await formControl.trigger()
                    
                    let fieldState = await formControl.getFieldState(name: .b)
                    expect(fieldState.isInvalid) == false
                    expect(fieldState.error).to(beEmpty())
                }
            }
            
            context("unregister \"b\"") {
                beforeEach {
                    await formControl.unregister(name: .b)
                }
                
                context("trigger both key \"a\" and \"b\", and validation of \"a\" returns false") {
                    beforeEach {
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                    }
                    
                    it("result of validation \"a\" is false, and errors of \"a\" equals [\"Failed to validate a\"]") {
                        let result = await formControl.trigger(name: .a, .b)
                        expect(result) == false
                        
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == true
                        expect(fieldState.error) == ["Failed to validate a"]
                    }
                    
                    it("key \"b\" is undefined") {
                        await formControl.trigger(name: .a, .b)
                        
                        let formState = await formControl.formState
                        expect(formState.defaultValues[.b]).to(beNil())
                        expect(formState.formValues[.b]).to(beNil())
                    }
                }
            }
            
            context("changes mode to .onChange") {
                beforeEach {
                    formControl.options.mode = .onChange
                }
                
                context("field \"a\" changes its value, and will be invalid") {
                    beforeEach {
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                        aBinder.wrappedValue = "a"
                        await formControl.syncFormState()
                    }
                    
                    it("field \"a\" is triggered, and is invalid") {
                        try? await Task.sleep(nanoseconds: 2_000_000)
                        
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == true
                        
                        let formState = await formControl.formState
                        expect(formState.errors[.a]) == ["Failed to validate a"]
                    }
                }
            }
            
            context("key \"a\" has been already invalid, and validation of \"a\" returns true") {
                beforeEach {
                    formControl.instantFormState.errors.setMessages(
                        name: .a, messages: [
                            "Failed to validate a"
                        ],
                        isValid: false
                    )
                    aValidator.result = true
                    aValidator.messages = []
                    await formControl.syncFormState()
                }
                
                context("changes reValidationMode to .onChange, and key \"a\" changes its value") {
                    beforeEach {
                        formControl.options.reValidateMode = .onChange
                        aBinder.wrappedValue = "a"
                    }
                    
                    it("field \"a\" is triggered, and is valid") {
                        try? await Task.sleep(nanoseconds: 2_000_000)
                        
                        let formState = await formControl.formState
                        expect(formState.errors[.a]) == []
                        
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == false
                    }
                }
                
                context("changes reValidationMode to .onSubmit, and key \"a\" changes its value") {
                    beforeEach {
                        formControl.options.reValidateMode = .onSubmit
                        aBinder.wrappedValue = "a"
                    }
                    
                    it("field \"a\" is triggered, and is still invalid") {
                        try? await Task.sleep(nanoseconds: 2_000_000)
                        
                        let fieldState = await formControl.getFieldState(name: .a)
                        expect(fieldState.isInvalid) == true
                        
                        let formState = await formControl.formState
                        expect(formState.errors[.a]) == ["Failed to validate a"]
                    }
                }
            }
        }
    }
    
    func resolverSpecs() {
        describe("Form Control registered field \"a\" and \"b\" with non-nil resolver") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            var bValidator: MockValidator<String, Bool>!
            let aDefaultValue = "%^$#"
            let bDefaultValue = "%^$#*("
            
            let resolverProxy = ResolverProxy<TestFieldName>(value: [
                .a: aDefaultValue,
                .b: bDefaultValue
            ])
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: resolverProxy.resolver(values:context:fieldNames:),
                    context: nil,
                    shouldUnregister: true,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: aDefaultValue))
                
                bValidator = MockValidator<String, Bool>(result: true)
                _ = formControl.register(name: .b, options: .init(rules: bValidator!, defaultValue: bDefaultValue))
            }
            
            context("resolver indicates all fields are valid") {
                context("validation of \"a\" returns failure") {
                    beforeEach {
                        aValidator.result = false
                        aValidator.messages = ["Failed to validate a"]
                    }
                    
                    context("reset field \"a\" with default options") {
                        beforeEach {
                            await formControl.reset(name: .a)
                        }
                        
                        it("all fields are valid") {
                            let formState = await formControl.formState
                            expect(formState.isValid) == true
                            expect(formState.errors[.a]).to(beNil())
                            expect(formState.errors[.b]).to(beNil())
                        }
                    }
                    
                    context("submit the form") {
                        beforeEach {
                            try? await formControl.handleSubmit(onValid: { _, _ in })
                        }
                        
                        it("all fields are valid") {
                            let formState = await formControl.formState
                            expect(formState.isValid) == true
                            expect(formState.errors[.a]).to(beNil())
                            expect(formState.errors[.b]).to(beNil())
                        }
                    }
                    
                    context("trigger field \"a\"") {
                        beforeEach {
                            await formControl.trigger(name: .a)
                        }
                        
                        it("all fields are valid") {
                            let formState = await formControl.formState
                            expect(formState.isValid) == true
                            expect(formState.errors[.a]).to(beNil())
                            expect(formState.errors[.b]).to(beNil())
                        }
                    }
                }
            }
            
            context("resolver indicates field \"a\" is invalid") {
                beforeEach {
                    let errors: FormError<TestFieldName> = .init(
                        errorFields: [.a],
                        messages: [
                            .a: ["Failed to validate a"]
                        ]
                    )
                    resolverProxy.result = .failure(errors)
                }
                
                context("submit the form") {
                    beforeEach {
                        try? await formControl.handleSubmit(onValid: { _, _ in })
                    }
                    
                    it("field \"a\" is invalid and \"b\" isn't") {
                        let formState = await formControl.formState
                        expect(formState.isValid) == false
                        expect(formState.errors[.a]) == ["Failed to validate a"]
                        expect(formState.errors[.b]).to(beNil())
                    }
                }
                
                context("trigger field \"a\"") {
                    beforeEach {
                        await formControl.trigger(name: .a)
                    }
                    
                    it("field \"a\" is invalid and \"b\" isn't") {
                        let formState = await formControl.formState
                        expect(formState.isValid) == false
                        expect(formState.errors[.a]) == ["Failed to validate a"]
                        expect(formState.errors[.b]).to(beNil())
                    }
                }
                
                context("reset field \"a\" with default options") {
                    beforeEach {
                        await formControl.reset(name: .a)
                    }
                    
                    it("field \"a\" is invalid and \"b\" isn't") {
                        let formState = await formControl.formState
                        expect(formState.isValid) == false
                        expect(formState.errors[.a]) == ["Failed to validate a"]
                        expect(formState.errors[.b]).to(beNil())
                    }
                }
            }
        }
    }
    
    func changeFieldValueSpecs() {
        describe("Form Control with shouldUnregister equals false registers a field \"a\" with a default value") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            let testDefaultValue = "%^$#"
            var aBinder: FieldRegistration<String>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: false,
                    shouldFocusError: true,
                    delayErrorInNanoseconds: 0,
                    onFocusedField: { _ in }
                )
                formControl = .init(options: options, formState: .init(
                    get: { formState },
                    set: { formState = $0 }
                ))
                
                aValidator = MockValidator<String, Bool>(result: true)
                aBinder = formControl.register(name: .a, options: .init(rules: aValidator!, defaultValue: testDefaultValue))
            }
            
            context("changes value for \"a\" to the original default value") {
                beforeEach {
                    aBinder.wrappedValue = testDefaultValue
                }
                
                it("key \"a\" is still not dirty") {
                    let fieldState = formControl.getFieldState(name: .a)
                    expect(fieldState.isDirty) == false
                }
                
                context("changes value for \"a\" to another value") {
                    beforeEach {
                        aBinder.wrappedValue = "a"
                    }
                    
                    it("key \"a\" is dirty") {
                        let fieldState = formControl.getFieldState(name: .a)
                        expect(fieldState.isDirty) == true
                    }
                }
            }
            
            context("changes value for \"a\" to another value") {
                beforeEach {
                    aBinder.wrappedValue = "a"
                }
                
                it("key \"a\" is dirty") {
                    let fieldState = formControl.getFieldState(name: .a)
                    expect(fieldState.isDirty) == true
                }
                
                context("changes value for \"a\" to the original default value") {
                    beforeEach {
                        aBinder.wrappedValue = testDefaultValue
                    }
                    
                    it("key \"a\" is still dirty") {
                        let fieldState = formControl.getFieldState(name: .a)
                        expect(fieldState.isDirty) == true
                    }
                }
            }
        }
    }
}

private class ResolverProxy<FieldName> where FieldName: Hashable {
    var result: Result<ResolverValue<FieldName>, ResolverError<FieldName>>

    init(value: ResolverValue<FieldName>) {
        self.result = .success(value)
    }

    init(error: ResolverError<FieldName>) {
        self.result = .failure(error)
    }

    func resolver(values: ResolverValue<FieldName>, context: Any?, fieldNames: [FieldName]) async -> Result<ResolverValue<FieldName>, ResolverError<FieldName>> {
        result
    }
}
