//
//  HookTests.swift
//  FormHookTests
//
//  Created by Robert on 01/01/2023.
//

import Foundation
import SwiftUI
import Testing
import Hooks

@testable import FormHook

@Suite("Hook Integration Tests")
struct HookTests {

    @Suite("useForm")
    struct UseFormTests {

        @Test("initiates a FormControl instance")
        func initiatesFormControlInstance() async {
            let useFormSpec = UseFormSpec()
            let options = FormOption<TestFieldName>(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            )
            await useFormSpec.refreshTester(options: options)

            #expect(useFormSpec.testerValue.options.mode == .onSubmit)
            #expect(useFormSpec.testerValue.options.reValidateMode == .onChange)
        }
    }

    @Suite("useForm with shouldUnregister true")
    struct UseControllerWithUnregisterTrueTests {

        @Test("key 'a' is registered when view updates")
        func keyAIsRegisteredWhenViewUpdates() async {
            let useControllerSpec = UseControllerSpec()
            await useControllerSpec.updateFormControl(options: FormOption(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            ), shouldUnregister: true)
            await useControllerSpec.formControl.syncFormState()

            let testerValue = useControllerSpec.testerValue
            #expect(testerValue.field.name == .a)
            #expect(areEqual(first: testerValue.formState.formValues[.a], second: "default A") == true)
            #expect(areEqual(first: testerValue.formState.defaultValues[.a], second: "default A") == true)
        }

        @Test("key 'a' is unregistered when view unmounts")
        func keyAIsUnregisteredWhenViewUnmounts() async {
            let useControllerSpec = UseControllerSpec()
            await useControllerSpec.updateFormControl(options: FormOption(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            ), shouldUnregister: true)
            await useControllerSpec.formControl.syncFormState()

            useControllerSpec.disposeTester()

            try? await Task.sleep(nanoseconds: 200_000_000)
            let formState = useControllerSpec.formControl.instantFormState
            #expect(formState.formValues[.a] == nil)
            #expect(formState.defaultValues[.a] == nil)
        }
    }

    @Suite("useForm with shouldUnregister false")
    struct UseControllerWithUnregisterFalseTests {

        @Test("key 'a' is registered when view updates")
        func keyAIsRegisteredWhenViewUpdates() async {
            let useControllerSpec = UseControllerSpec()
            await useControllerSpec.updateFormControl(options: FormOption(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            ))
            await useControllerSpec.formControl.syncFormState()

            let testerValue = useControllerSpec.testerValue
            #expect(testerValue.field.name == .a)
            #expect(areEqual(first: testerValue.formState.formValues[.a], second: "default A") == true)
            #expect(areEqual(first: testerValue.formState.defaultValues[.a], second: "default A") == true)
        }

        @Test("key 'a' is unregistered but data remains when view unmounts")
        func keyAIsUnregisteredButDataRemainsWhenViewUnmounts() async {
            let useControllerSpec = UseControllerSpec()
            await useControllerSpec.updateFormControl(options: FormOption(
                mode: .onSubmit,
                reValidateMode: .onChange,
                resolver: nil,
                context: nil,
                shouldUnregister: true,
                shouldFocusError: true,
                delayErrorInNanoseconds: 0,
                onFocusField: { _ in }
            ))
            await useControllerSpec.formControl.syncFormState()

            useControllerSpec.disposeTester()

            let formState = await useControllerSpec.formControl.formState
            #expect(areEqual(first: formState.formValues[.a], second: "default A") == true)
            #expect(areEqual(first: formState.defaultValues[.a], second: "default A") == true)
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