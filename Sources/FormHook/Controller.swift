//
//  Controller.swift
//  swiftui-hooks-form
//
//  Created by Robert on 07/11/2022.
//

import Foundation
import SwiftUI
import Hooks

public struct FieldOption<FieldName, Value> where FieldName: Hashable {
    public let onChange: (() -> Void)?
    public let onBlur: (() -> Void)?
    public let value: Value
    public let name: FieldName
}

public struct ControllerRenderOption<FieldName, Value> where FieldName: Hashable {
    public let field: FieldOption<FieldName, Value>
    public let fieldState: FieldState
    public let formState: FormState<FieldName>
}

public struct Controller<Content, FieldName, Value>: HookView where Content: View, FieldName: Hashable, Value: Comparable {
    let name: FieldName
    let control: Control
    let defaultValue: Value
    let rules: Rule<FieldName, Value>
    let render: (ControllerRenderOption<FieldName, Value>) -> Content

    public init(
        name: FieldName,
        control: Control,
        defaultValue: Value,
        rules: Rule<FieldName, Value>,
        @ViewBuilder render: @escaping (ControllerRenderOption<FieldName, Value>) -> Content
    ) {
        self.name = name
        self.control = control
        self.defaultValue = defaultValue
        self.rules = rules
        self.render = render
    }

    public var hookBody: some View {
        let renderOption = useController(name: name, control: control, defaultValue: defaultValue, rules: rules)
        return render(renderOption)
    }
}
