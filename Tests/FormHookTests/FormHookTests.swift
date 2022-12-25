#if os(iOS) || os(tvOS)
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
}

protocol ResultControllableValidator: Validator where Result: BoolConvertible {
    var result: Result { get }
    var messages: [String] { get }
}

extension ResultControllableValidator {
    func validate(_ value: Value) async -> Result {
        result
    }
    
    func generateMessage(result: Result) -> [String] {
        messages
    }
}

class MockValidator<Value, Result>: ResultControllableValidator where Result: BoolConvertible {
    var result: Result
    var messages: [String]
    
    init(result: Result, messages: [String] = []) {
        self.result = result
        self.messages = messages
    }
}
#endif
