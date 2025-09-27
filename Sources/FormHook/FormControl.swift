//
//  FormControl.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import SwiftUI
import Hooks

/// A control that holds form information
public class FormControl<FieldName> where FieldName: Hashable {
    var options: FormOption<FieldName>

    internal var currentErrorNotifyTask: Task<Void, Error>?
    internal var fields: [FieldName: FieldProtocol]

    internal var _currentFocusedField: FieldName?

    @MainActor
    internal var currentFocusedField: FieldName? {
        get {
            _currentFocusedField ?? options.focusedFieldOption.focusedFieldBindingValue
        }
        set {
            if let newValue {
                options.focusedFieldOption.triggerFocus(on: newValue)
            }
            if options.focusedFieldOption.hasFocusedFieldBinder {
                return
            }
            _currentFocusedField = newValue
        }
    }

    var instantFormState: FormState<FieldName>
    @MainActor @Binding
    internal(set) public var formState: FormState<FieldName>

    init(options: FormOption<FieldName>, formState: Binding<FormState<FieldName>>) {
        self.options = options
        self.fields = [:]
        self._formState = formState
        self.instantFormState = formState.wrappedValue
    }

    /// Register an input or select element and apply validation rules to SwiftUI Hook Form
    /// - Parameters:
    ///     - name: The name of the field.
    ///     - options: The options for the field, such as its default value and field ordinal.
    /// - Returns: A `FieldRegistration` object containing the value of the field.
    public func register<Value>(name: FieldName, options: RegisterOption<Value>) -> FieldRegistration<Value> {
        self.instantFormState.defaultValues[name] = options.defaultValue
        let field: Field<Value>
        if let f = fields[name] as? Field<Value> {
            field = f
            if !areEqual(first: options.defaultValue, second: field.options.defaultValue) && !instantFormState.dirtyFields.contains(name) {
                instantFormState.formValues[name] = options.defaultValue
            }
            field.options = options
            if let fieldOrdinal = options.fieldOrdinal {
                field.fieldOrdinal = fieldOrdinal
            }
        } else {
            field = Field(fieldOrdinal: options.fieldOrdinal ?? fields.count, name: name, options: options, control: self)
            fields[name] = field
            instantFormState.formValues[name] = options.defaultValue
        }
        return field.value
    }

    deinit {
        currentErrorNotifyTask?.cancel()
        currentErrorNotifyTask = nil
    }

    /// Unregister a single input or an array of inputs
    /// - Parameters:
    ///   - names: The name(s) of the input(s) to unregister.
    ///   - options: Options for unregistering the input(s).
    public func unregister(names: [FieldName], options: UnregisterOption = []) async {
        if self.options.shouldUnregister {
            names.forEach { fields[$0] = nil }
        }
        names.forEach {
            if fields[$0]?.shouldUnregister ?? false {
                fields[$0] = nil
            }
        }
        if !options.contains(.keepValue) {
            names.forEach { instantFormState.formValues[$0] = nil }
        }
        if !options.contains(.keepError) {
            names.forEach { instantFormState.errors.removeMessagesOnly(name: $0) }
        }
        if !options.contains(.keepDirty) {
            names.forEach { instantFormState.dirtyFields.remove($0) }
        }
        if !options.contains(.keepDefaultValue) {
            names.forEach { instantFormState.defaultValues[$0] = nil }
        }
        if !options.contains(.keepIsValid) {
            names.forEach { instantFormState.errors.removeValidityOnly(name: $0) }
        }

        // Only call updateValid if we're not preserving validity or errors
        // because updateValid() replaces the entire errors object
        if !options.contains(.keepIsValid) && !options.contains(.keepError) {
            await updateValid()
        }

        await syncFormState()
    }

    /// Unregister a single input or an array of inputs
    /// - Parameters:
    ///   - name: The name(s) of the input(s) to unregister.
    ///   - options: Options for unregistering the field name.
    public func unregister(name: FieldName..., options: UnregisterOption = []) async {
        await unregister(names: name, options: options)
    }

    /// Handles the submission of a form.
    /// - Parameters:
    ///     - onValid: A closure that is called when the form is valid. It takes two arguments: the form value and any errors that were encountered.
    ///     - onInvalid: An optional closure that is called when the form is invalid. It takes two arguments: the form value and any errors that were encountered. If not provided, an error will be thrown instead.
    public func handleSubmit(
        @_implicitSelfCapture onValid: @escaping (FormValue<FieldName>, FormError<FieldName>) async throws -> Void,
        @_implicitSelfCapture onInvalid: ((FormValue<FieldName>, FormError<FieldName>) async throws -> Void)? = nil
    ) async throws {
        instantFormState.submissionState = .submitting
        let errors: FormError<FieldName>
        var isOverallValid: Bool
        if options.mode.contains(.onSubmit) {
            instantFormState.isValidating = true
            await syncFormState()
            if let resolver = options.resolver {
                let result = await resolver(
                    instantFormState.formValues,
                    options.context,
                    Array(fields.keys)
                )
                switch result {
                case .success(let formValues):
                    isOverallValid = true
                    errors = .init()
                    instantFormState.formValues.unioned(formValues)
                case .failure(let e):
                    isOverallValid = false
                    errors = e
                }
            } else {
                (isOverallValid, errors) = await validateAllFields()
            }
            instantFormState.isValidating = false
            await syncFormState()
        } else if options.reValidateMode.contains(.onSubmit) {
            instantFormState.isValidating = true
            await syncFormState()
            if let resolver = options.resolver {
                let names = fields.keys.filter(instantFormState.errors.errorFields.contains)
                let result = await resolver(instantFormState.formValues, options.context, names)
                switch result {
                case .success(let formValues):
                    isOverallValid = true
                    errors = .init()
                    instantFormState.formValues.unioned(formValues)
                case .failure(let e):
                    isOverallValid = false
                    errors = e
                }
            } else {
                (isOverallValid, errors) = await revalidateErrorFields()
            }
            instantFormState.isValidating = false
            await syncFormState()
        } else {
            await syncFormState()
            isOverallValid = instantFormState.isValid
            errors = instantFormState.errors
        }
        do {
            if isOverallValid {
                try await onValid(instantFormState.formValues, errors)
            } else if let onInvalid {
                try await onInvalid(instantFormState.formValues, errors)
            }
            await postHandleSubmit(isOverallValid: isOverallValid, errors: errors, isSubmitSuccessful: errors.errorFields.isEmpty)
        } catch {
            await postHandleSubmit(isOverallValid: isOverallValid, errors: errors, isSubmitSuccessful: false)
            throw error
        }
    }

    /// Reset the entire form state, fields reference, and subscriptions. There are optional arguments and will allow partial form state reset.
    /// - Parameters:
    ///   - defaultValues: A `FormValue` containing the default values for each field.
    ///   - options: An optional array of `ResetOption`s which will allow partial form state reset.
    public func reset(defaultValues: FormValue<FieldName>, options: ResetOption = []) async {
        for (name, defaultValue) in defaultValues {
            if let defaultValue = Optional.some(defaultValue).flattened() {
                if !options.contains(.keepDefaultValues) {
                    instantFormState.defaultValues[name] = defaultValue
                }
            } else {
                assertionFailure("defaultValue must not be nil")
            }
            if !options.contains(.keepValues) {
                instantFormState.formValues[name] = defaultValue
            }
        }
        defaultValues.keys.forEach { name in
            if !options.contains(.keepDirty) {
                instantFormState.dirtyFields.remove(name)
            }
            if !options.contains(.keepErrors) {
                instantFormState.errors.removeMessagesOnly(name: name)
            }
        }
        if !options.contains(.keepIsValid) {
            instantFormState.isValid = true
        }
        if !options.contains(.keepIsSubmitted) {
            instantFormState.submissionState = .notSubmit
            instantFormState.isSubmitSuccessful = false
        }
        if !options.contains(.keepSubmitCount) {
            instantFormState.submitCount = 0
        }
        if !options.contains(.keepErrors) {
            await updateValid()
        }
        return await syncFormState()
    }

    /// Resets an individual field state.
    /// - Parameters:
    ///   - name: The name of the field to reset.
    ///   - defaultValue: The default value of the field. Must not be nil.
    ///   - options: Options for resetting the field.
    public func reset(name: FieldName, defaultValue: Any, options: SingleResetOption = []) async {
        guard let defaultValue = Optional.some(defaultValue).flattened() else {
            assertionFailure("defaultValue must not be nil")
            return
        }
        instantFormState.defaultValues[name] = defaultValue
        await reset(name: name, options: options)
    }

    /// Resets an individual field state.
    /// - Parameters:
    ///   - name: The name of the field to reset.
    ///   - options: Options for resetting the field.
    public func reset(name: FieldName, options: SingleResetOption = []) async {
        instantFormState.formValues[name] = instantFormState.defaultValues[name]
        if !options.contains(.keepDirty) {
            instantFormState.dirtyFields.remove(name)
        }
        if !options.contains(.keepError) {
            instantFormState.errors.remove(name: name)
            await updateValid()
        }
        return await syncFormState()
    }

    /// This function can manually clear errors in the form.
    /// - Parameters:
    ///   - names: An array of `FieldName`s to remove errors from.
    public func clearErrors(names: [FieldName]) async {
        names.forEach { name in
            instantFormState.errors.remove(name: name)
        }
        await syncFormState()
    }

    /// This function can manually clear errors in the form.
    /// - Parameters:
    ///   - name: A variadic list of `FieldName`s to remove errors from.
    public func clearErrors(name: FieldName...) async {
        await clearErrors(names: name)
    }

    /// Sets the value of a registered field and updates the form state.
    /// - Parameters:
    ///   - name: The name of the field to set.
    ///   - value: The value to set for the field.
    ///   - options: An array of `SetValueOption`s that determine how the form state should be updated.
    /// - Returns: An asynchronous task that returns when the form state has been updated.
    public func setValue(name: FieldName, value: Any, options: SetValueOption = []) async {
        instantFormState.formValues[name] = value
        if options.contains(.shouldDirty) || !areEqual(first: value, second: instantFormState.defaultValues[name]) {
            instantFormState.dirtyFields.insert(name)
        }
        guard options.contains(.shouldValidate) else {
            return await syncFormState()
        }
        await trigger(name: name)
    }

    /// Return individual field state
    /// - Parameter name: The name of the field to get the state of.
    /// - Returns: A `FieldState` object containing information about a single field in a form state object.
    public func getFieldState(name: FieldName) -> FieldState {
        instantFormState.getFieldState(name: name)
    }

    /// Return individual field state asynchronously
    /// - Parameter name: The name of the field to get the state of.
    /// - Returns: A `FieldState` object containing information about a single field in a form state object.
    public func getFieldState(name: FieldName) async -> FieldState {
        await formState.getFieldState(name: name)
    }

    /// Manually triggers form or input validation. This method is also useful when you have dependant validation (input validation depends on another input's value).
    ///  - Parameters:
    ///     - names: An array of `FieldName`s to be validated.
    ///     - shouldFocus: A boolean indicating whether the field should be focused after validation. Defaults to `false`.
    ///  - Returns: A boolean indicating whether all validations passed successfully or not.
    @discardableResult
    public func trigger(names: [FieldName], shouldFocus: Bool = false) async -> Bool {
        let validationNames = names.isEmpty ? fields.map { $0.key } : names
        instantFormState.isValidating = true
        await syncFormState()
        let isValid: Bool
        let errors: FormError<FieldName>
        if let resolver = options.resolver {
            let result = await resolver(instantFormState.formValues, options.context, validationNames)
            switch result {
            case .success(let formValues):
                isValid = true
                errors = instantFormState.errors
                instantFormState.formValues.unioned(formValues)
            case .failure(let e):
                isValid = false
                errors = instantFormState.errors.union(e)
            }
        } else {
            (isValid, errors) = await validateFields(fieldNames: validationNames)
        }
        if !isValid {
            instantFormState.isValid = isValid
        }
        instantFormState.isValidating = false

        currentErrorNotifyTask?.cancel()
        if options.delayErrorInNanoseconds == 0 || isValid {
            currentErrorNotifyTask = nil
            instantFormState.errors = errors
            await syncFormState()
            if shouldFocus {
                await focusFieldAfterTrigger(validatedFieldNames: validationNames, errorFields: errors.errorFields)
            }
        } else {
            await syncFormState()
            let delayErrorInNanoseconds = options.delayErrorInNanoseconds
            currentErrorNotifyTask = Task { [weak self] in
                try await Task.sleep(nanoseconds: delayErrorInNanoseconds)
                self?.instantFormState.errors = errors
                await self?.syncFormState()
                if shouldFocus {
                    await self?.focusFieldAfterTrigger(validatedFieldNames: validationNames, errorFields: errors.errorFields)
                }
            }
        }
        return isValid
    }

    /// Manually triggers form or input validation. This method is also useful when you have dependant validation (input validation depends on another input's value).
    ///  - Parameters:
    ///     - names: variadic list of `FieldName`s to be validated.
    ///     - shouldFocus: A boolean indicating whether the field should be focused after validation. Defaults to `false`.
    ///  - Returns: A boolean indicating whether all validations passed successfully or not.
    @discardableResult
    public func trigger(name: FieldName..., shouldFocus: Bool = false) async -> Bool {
        await trigger(names: name, shouldFocus: shouldFocus)
    }
}