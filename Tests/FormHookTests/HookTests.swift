//
//  HookTests.swift
//  FormHookTests
//
//  Created by Robert on 01/01/2023.
//

import Foundation
import SwiftUI
import Quick
import Nimble
import Hooks

@testable import FormHook

class HookTests: QuickSpec {
    override func spec() {
        useFormSpecs()
        useControllerSpecs()
    }
    
    func useFormSpecs() {
        describe("useForm") {
            let useFormSpec = UseFormSpec()
            
            beforeEach {
                let options = FormOption<TestFieldName>(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    delayError: true
                )
                await useFormSpec.refreshTester(options: options)
            }
            
            it("initiates a FormControl instance") {
                expect(useFormSpec.testerValue.options.mode) == .onSubmit
                expect(useFormSpec.testerValue.options.reValidateMode) == .onChange
            }
        }
    }
    
    func useControllerSpecs() {
        describe("useForm with shouldUnregister is true, default unregister options, and formControl synchronizes its state") {
            let useControllerSpec = UseControllerSpec()
            
            beforeEach {
                await useControllerSpec.updateFormControl(options: FormOption(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    delayError: true
                ), shouldUnregister: true)
                await useControllerSpec.formControl.syncFormState()
            }
            
            context("view updates") {
                it("key \"a\" is registered") {
                    let testerValue = useControllerSpec.testerValue
                    expect(testerValue.field.name) == .a
                    expect(areEqual(first: testerValue.formState.formValues[.a], second: "default A")) == true
                    expect(areEqual(first: testerValue.formState.defaultValues[.a], second: "default A")) == true
                }
                
                context("view unmounts") {
                    beforeEach {
                        useControllerSpec.disposeTester()
                    }
                    
                    it("key \"a\" is unregistered") {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        let formState = await useControllerSpec.formControl.formState
                        expect(formState.formValues[.a]).to(beNil())
                        expect(formState.defaultValues[.a]).to(beNil())
                    }
                }
            }
        }
        
        describe("useForm with shouldUnregister is false, default unregister options, and formControl synchronizes its state") {
            let useControllerSpec = UseControllerSpec()
            
            beforeEach {
                await useControllerSpec.updateFormControl(options: FormOption(
                    mode: .onSubmit,
                    reValidateMode: .onChange,
                    resolver: nil,
                    context: nil,
                    shouldUnregister: true,
                    delayError: true
                ))
                await useControllerSpec.formControl.syncFormState()
            }
            
            context("view updates") {
                it("key \"a\" is registered") {
                    let testerValue = useControllerSpec.testerValue
                    expect(testerValue.field.name) == .a
                    expect(areEqual(first: testerValue.formState.formValues[.a], second: "default A")) == true
                    expect(areEqual(first: testerValue.formState.defaultValues[.a], second: "default A")) == true
                }
                
                context("view unmounts") {
                    beforeEach {
                        useControllerSpec.disposeTester()
                    }
                    
                    it("key \"a\" is unregistered but data remains") {
                        let formState = await useControllerSpec.formControl.formState
                        expect(areEqual(first: formState.formValues[.a], second: "default A")) == true
                        expect(areEqual(first: formState.defaultValues[.a], second: "default A")) == true
                    }
                }
            }
        }
    }
}

private class UseControllerSpec {
    private var tester: HookTester<Void, ControllerRenderOption<TestFieldName, String>>!
    var formControl: FormControl<TestFieldName>!
    
    func updateFormControl(options: FormOption<TestFieldName>, shouldUnregister: Bool = false) async {
        var formState: FormState<TestFieldName> = .init()
        self.formControl = .init(options: options, formState: .init(
            get: { formState },
            set: { formState = $0 }
        ))
        await MainActor.run {
            self.tester = createTester(shouldUnregister: shouldUnregister)
        }
    }
    
    func updateShouldUnregister(_ shouldUnregister: Bool) async {
        await MainActor.run {
            self.tester = createTester(shouldUnregister: shouldUnregister)
        }
    }
    
    func createTester(shouldUnregister: Bool) -> HookTester<Void, ControllerRenderOption<TestFieldName, String>> {
        HookTester {
            useController(name: .a, defaultValue: "default A", rules: NoopValidator(), shouldUnregister: shouldUnregister)
        } environment: {
            $0[TestFormContext.self] = self.formControl
        }
    }
    
    func updateTester() async {
        await MainActor.run {
            self.tester.update()
        }
    }
    
    func disposeTester() {
        tester.dispose()
    }
    
    var testerValue: ControllerRenderOption<TestFieldName, String> {
        tester.value
    }
}

private class UseFormSpec {
    private var tester: HookTester<Void, FormControl<TestFieldName>>!
    
    func refreshTester(options: FormOption<TestFieldName>) async {
        await MainActor.run {
            self.tester = createTester(options: options)
        }
    }
    
    func createTester(options: FormOption<TestFieldName>) -> HookTester<Void, FormControl<TestFieldName>> {
        HookTester {
            useForm(options)
        }
    }

    func updateTester() async {
        await MainActor.run {
            self.tester.update()
        }
    }
    
    func disposeTester() {
        tester.dispose()
    }
    
    var testerValue: FormControl<TestFieldName> {
        tester.value
    }
}

private typealias TestFormContext = Context<FormControl<TestFieldName>>
