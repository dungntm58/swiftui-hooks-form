//
//  FormExtensions.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import SwiftUI
import Hooks

// MARK: - Public FormControl Extensions

extension FormControl {
    func updateValid() async {
        guard instantFormState.isValid else {
            return
        }
        if let resolver = options.resolver {
            let result = await resolver(instantFormState.formValues, options.context, Array(fields.keys))
            switch result {
            case .success(let formValues):
                instantFormState.isValid = true
                instantFormState.formValues.unioned(formValues)
                await syncFormState()
            case .failure(let e):
                await onResultPostUpdateValid(e, isValid: false)
            }
            return
        }
        let (isValid, errors) = await validateAllFields(shouldStopOnFirstError: true)
        await onResultPostUpdateValid(errors, isValid: isValid)
    }

    @MainActor
    func syncFormState() {
        if formState == instantFormState {
            return
        }
        formState = instantFormState
    }
}

// MARK: - Private FormControl Extensions

extension FormControl {
    class Field<Value>: FieldProtocol {
        var fieldOrdinal: Int
        let name: FieldName
        var options: RegisterOption<Value> {
            didSet {
                if areEqual(first: oldValue.defaultValue, second: options.defaultValue) {
                    return
                }
                value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
            }
        }
        unowned var control: FormControl<FieldName>
        var value: Binding<Value>

        init(fieldOrdinal: Int, name: FieldName, options: RegisterOption<Value>, control: FormControl<FieldName>) {
            self.fieldOrdinal = fieldOrdinal
            self.name = name
            self.options = options
            self.control = control
            self.value = control.computeValueBinding(name: name, defaultValue: options.defaultValue)
        }

        var shouldUnregister: Bool {
            options.shouldUnregister
        }

        func computeMessages() async -> (Bool, [String]) {
            await options.rules.computeMessage(value: value.wrappedValue)
        }
    }

    internal func computeValueBinding<Value>(name: FieldName, defaultValue: Value) -> Binding<Value> {
        .init { [weak self] in
            self?.instantFormState.formValues[name] as? Value ?? defaultValue
        } set: { [weak self] value in
            guard let self else {
                return
            }
            self.instantFormState.formValues[name] = value
            if !self.instantFormState.dirtyFields.contains(name) && !areEqual(first: self.instantFormState.defaultValues[name], second: value) {
                self.instantFormState.dirtyFields.insert(name)
            }
            guard self.shouldReValidateOnChange(name: name) else {
                return
            }
            Task {
                await self.trigger(name: name, shouldFocus: true)
            }
        }
    }

    internal func shouldReValidateOnChange(name: FieldName) -> Bool {
        if options.mode.contains(.onChange) {
            return true
        }
        guard instantFormState.errors.errorFields.contains(name) else {
            return false
        }
        return options.reValidateMode.contains(.onChange)
    }

    internal func postHandleSubmit(isOverallValid: Bool, errors: FormError<FieldName>, isSubmitSuccessful: Bool) async {
        instantFormState.submissionState = .submitted
        instantFormState.isSubmitSuccessful = isSubmitSuccessful
        instantFormState.submitCount += 1
        await onResultPostUpdateValid(errors, isValid: isOverallValid)
    }

    @MainActor
    internal func focusFieldAfterTrigger(validatedFieldNames: [FieldName], errorFields: Set<FieldName>) {
        let focusField: FieldName?
        if validatedFieldNames.count == 1  {
            focusField = validatedFieldNames[0]
            if currentFocusedField != nil && currentFocusedField != focusField {
                return
            }
        } else {
            focusField = validatedFieldNames.first(where: errorFields.contains)
        }
        guard let focusField else {
            return
        }
        currentFocusedField = focusField
    }

    internal func onResultPostUpdateValid(_ errors: FormError<FieldName>, isValid: Bool) async {
        instantFormState.isValid = isValid
        currentErrorNotifyTask?.cancel()
        if options.delayErrorInNanoseconds == 0 || isValid {
            currentErrorNotifyTask = nil
            instantFormState.errors = errors
            await syncFormState()
            return await focusError(with: errors)
        }
        await syncFormState()
        let delayErrorInNanoseconds = options.delayErrorInNanoseconds
        currentErrorNotifyTask = Task { [weak self] in
            try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
            self?.instantFormState.errors = errors
            await self?.syncFormState()
            await self?.focusError(with: errors)
        }
    }

    @MainActor
    internal func focusError(with errors: FormError<FieldName>) {
        guard options.shouldFocusError else {
            return
        }
        let fields = fields.sorted { $0.value.fieldOrdinal < $1.value.fieldOrdinal }
        let firstErrorField = fields.first(where: { errors.errorFields.contains($0.key) })?.key
        guard let firstErrorField else {
            return
        }
        currentFocusedField = firstErrorField
    }
}

// MARK: - Supporting Types

extension FormControl {
    struct KeyValidationResult {
        let key: FieldName
        let isValid: Bool
        let messages: [String]
    }
}