//
//  UseController.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Foundation
import Hooks

/// Use the `useController` hook to register a field with a form.
/// - Note: `FieldName` must conform to the `Hashable` protocol.
/// - Parameters:
///   - form: The `FormControl` to register the field with. If not provided, the hook will attempt to find an existing `FormControl` in the component tree.
///   - name: The name of the field being registered. This should be unique within the form.
///   - defaultValue: The default value of the field. This will be used if no value is set for this field on submission.
///   - rules: A validator that will be used to validate this field's value when it is submitted.
///   - shouldUnregister: A boolean indicating whether or not this field should be unregistered when the component unmounts (defaults to true).
///   - unregisterOption: An array of options that can be passed to `form.unregister()`. These are only used if `shouldUnregister` is true (defaults to an empty array). 
///   - fieldOrdinal: An optional integer indicating where in the form this field should appear (defaults to nil). 
/// - Returns: A tuple containing a `FieldOption`, a `FieldState`, and a `FormState`.
public func useController<FieldName, Value>(
    form: FormControl<FieldName>? = nil,
    name: FieldName,
    defaultValue: Value,
    rules: any Validator<Value>,
    shouldUnregister: Bool = true,
    unregisterOption: UnregisterOption = [],
    fieldOrdinal: Int? = nil
) -> ControllerRenderOption<FieldName, Value> where FieldName: Hashable {
    let form = form ?? useContext(Context<FormControl<FieldName>>.self)
    let registration = form.register(name: name, options: RegisterOption(fieldOrdinal: fieldOrdinal, rules: rules, defaultValue: defaultValue, shouldUnregister: shouldUnregister))

    let preservedChangedArray = [
        AnyEquatable(name),
        AnyEquatable(shouldUnregister),
        AnyEquatable(unregisterOption),
        AnyEquatable(form)
    ]
    useEffect(.preserved(by: preservedChangedArray)) {{
        guard shouldUnregister else { return }
        Task {
            await form.unregister(name: name, options: unregisterOption)
        }
    }}

    let field = FieldOption(
        name: name,
        value: registration
    )
    let fieldState = form.getFieldState(name: name)
    return (field: field, fieldState: fieldState, formState: form.instantFormState)
}
