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
        unregisterSpecs()
        resetSingleFieldSpecs()
        resetFormSpecs()
        clearErrorsSpecs()
    }
    
    func unregisterSpecs() {
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
                    criteriaMode: .all,
                    delayError: true
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
                            let isDirty = await formControl.getFieldState(name: .a).isDirty
                            expect(isDirty) == false
                        }
                    }
                }
                
                context("with option .keepValue") {
                    beforeEach {
                        await formControl.unregister(name: .a, options: .keepValue)
                    }
                    
                    it("value of key \"a\" remains") {
                        let formState = await formControl.formState
                        expect(areEqual(first: formState.formValues[.a], second: testDefaultValue)) == true
                    }
                }
                
                context("with option .keepDefaultValue") {
                    beforeEach {
                        await formControl.unregister(name: .a, options: .keepDefaultValue)
                    }
                    
                    it("default value of key \"a\" remains") {
                        let formState = await formControl.formState
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
                            expect(fieldState.error.isEmpty) == true
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
                            expect(fieldState.error.isEmpty) == true
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
                            let fieldState = await formControl.getFieldState(name: .a)
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
        describe("Form Control registered field \"a\"") {
            var formControl: FormControl<TestFieldName>!
            var aValidator: MockValidator<String, Bool>!
            let testDefaultValue = "%^$#"
            let testDefaultValue2 = "%^$#*("
            var aBinder: Binding<String>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    criteriaMode: .all,
                    delayError: true
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
                                expect(fieldState.error.isEmpty) == true
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
            
            var aBinder: Binding<String>!
            var bBinder: Binding<String>!
            
            beforeEach {
                var formState: FormState<TestFieldName> = .init()
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    criteriaMode: .all,
                    delayError: true
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
//                        expect(fieldState.isInvalid) == true
                        expect(fieldState.error.count) == 1
                        expect(fieldState.error.first) == "Failed to validate a"
                    }
                    
                    it("key \"b\" remains errors") {
                        let fieldState = await formControl.getFieldState(name: .b)
                        expect(fieldState.isInvalid) == false
                        expect(fieldState.error.isEmpty) == true
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
//                        expect(fieldState.isInvalid) == true
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
                    criteriaMode: .all,
                    delayError: true
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
                        expect(fieldState.error.isEmpty) == true
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
}
