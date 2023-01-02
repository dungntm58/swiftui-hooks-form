//
//  Controller.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Foundation
import SwiftUI
import Hooks

public struct FieldOption<FieldName, Value> {
    public let name: FieldName
    public let value: Binding<Value>

    init(name: FieldName, value: Binding<Value>) {
        self.name = name
        self.value = value
    }
}

public typealias ControllerRenderOption<FieldName, Value> = (field: FieldOption<FieldName, Value>, fieldState: FieldState, formState: FormState<FieldName>) where FieldName: Hashable

public struct Controller<Content, FieldName, Value>: View where Content: View, FieldName: Hashable {
    let name: FieldName
    let defaultValue: Value
    let rules: any Validator<Value>
    let shouldUnregister: Bool
    let unregisterOption: UnregisterOption
    let render: (ControllerRenderOption<FieldName, Value>) -> Content

    public init(
        name: FieldName,
        defaultValue: Value,
        rules: any Validator<Value> = NoopValidator(),
        shouldUnregister: Bool = true,
        unregisterOption: UnregisterOption = [],
        @ViewBuilder render: @escaping (ControllerRenderOption<FieldName, Value>) -> Content
    ) {
        self.name = name
        self.defaultValue = defaultValue
        self.rules = rules
        self.render = render
        self.shouldUnregister = true
        self.unregisterOption = unregisterOption
    }

    public var body: some View {
        HookScope {
            let renderOption = useController(name: name, defaultValue: defaultValue, rules: rules, shouldUnregister: shouldUnregister, unregisterOption: unregisterOption)
            render(renderOption)
        }
    }
}
