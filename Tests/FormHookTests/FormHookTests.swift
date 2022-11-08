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
        describe("") {
            var formControl: FormControl<TestFieldName>!
            
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
            }
            
            context("") {
                let testDefaultValue = "%^$#"
                
                beforeEach {
                    
                }
                
                it("") {
                    let value = formControl.register(name: .a, options: .init(rules: NoopValidator(), defaultValue: testDefaultValue))
                    expect(value.wrappedValue) == testDefaultValue
                    expect(areEqual(first: formControl.instantFormState.defaultValues[.a], second: testDefaultValue)) == true
                }
            }
            
            context("") {
                let testDefaultValue = "%^$#"
                
                beforeEach {
                    _ = formControl.register(name: .a, options: .init(rules: NoopValidator(), defaultValue: testDefaultValue))
                }
                
                it("") {
                    await formControl.unregister(name: .a, options: .keepValue)
                    let formState = await formControl.formState
                    
                    expect(areEqual(first: formState.formValues[.a], second: testDefaultValue)) == true
                }
                
                it("") {
                    await formControl.unregister(name: .a, options: .keepDefaultValue)
                    let formState = await formControl.formState
                    
                    expect(areEqual(first: formState.formValues[.a], second: testDefaultValue)) == true
                }
            }
        }
    }
}
