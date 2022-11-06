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
    control: Control,
    defaultValue: Value,
    rules: Rule<FieldName, Value>,
    shouldUnregister: Bool = false
) -> ControllerRenderOption<FieldName, Value> where FieldName: Hashable, Value: Comparable {
    fatalError()
}
