//
//  Controller.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Foundation
import Hooks
import SwiftUI

/// A convenient view that wraps a call of `useController`
public struct Controller<Content, FieldName, Value>: View where Content: View, FieldName: Hashable {
    let form: FormControl<FieldName>?
    let name: FieldName
    let defaultValue: Value
    let rules: any Validator<Value>
    let shouldUnregister: Bool
    let unregisterOption: UnregisterOption
    let fieldOrdinal: Int?
    let render: (ControllerRenderOption<FieldName, Value>) -> Content

    /// Initialize a `Controller` view
    /// - Parameters:
    ///     - form: The `FormControl` associated with the controller.
    ///     - name: The name of the field associated with the controller.
    ///     - defaultValue: The default value for the field associated with the controller.
    ///     - rules: A validator to be used to validate the value of the field associated with the controller.
    ///     - shouldUnregister: A boolean indicating whether or not to unregister the field from its form when it is no longer in use. Defaults to true.
    ///     - unregisterOption: An array of options for how to unregister a field from its form when it is no longer in use. Defaults to an empty array.
    ///     - fieldOrdinal: An optional integer indicating the order in which fields should be focused. Defaults to nil.
    ///     - render: A closure that takes a ControllerRenderOption and returns a View object representing what should be rendered for this controller.
    public init(
        form: FormControl<FieldName>? = nil,
        name: FieldName,
        defaultValue: Value,
        rules: any Validator<Value> = NoopValidator(),
        shouldUnregister: Bool = true,
        unregisterOption: UnregisterOption = [],
        fieldOrdinal: Int? = nil,
        @ViewBuilder render: @escaping (ControllerRenderOption<FieldName, Value>) -> Content
    ) {
        self.form = form
        self.name = name
        self.defaultValue = defaultValue
        self.rules = rules
        self.render = render
        self.shouldUnregister = shouldUnregister
        self.unregisterOption = unregisterOption
        self.fieldOrdinal = fieldOrdinal
    }

    public var body: some View {
        HookScope {
            let renderOption = useController(
                form: form,
                name: name,
                defaultValue: defaultValue,
                rules: rules,
                shouldUnregister: shouldUnregister,
                unregisterOption: unregisterOption,
                fieldOrdinal: fieldOrdinal
            )
            render(renderOption)
        }
    }
}
