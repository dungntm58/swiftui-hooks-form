//
//  UseController.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Foundation
import Hooks

public func useController<FieldName, Value>(
    name: FieldName,
    defaultValue: Value,
    rules: any Validator<Value>,
    shouldUnregister: Bool = true,
    unregisterOption: UnregisterOption = []
) -> ControllerRenderOption<FieldName, Value> where FieldName: Hashable {
    let form = useContext(Context<FormControl<FieldName>>.self)
    let registration = form.register(name: name, options: RegisterOption(rules: rules, defaultValue: defaultValue, shouldUnregister: shouldUnregister))

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
