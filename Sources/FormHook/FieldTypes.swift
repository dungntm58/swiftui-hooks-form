//
//  FieldTypes.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import Hooks
import SwiftUI

/// A type that represents a field option.
///
/// The `FieldOption` type is used to represent a field option. It consists of a `name` and a `value` of type `Binding<Value>`. The `Binding` type is used to create two-way bindings between a view and its underlying model.
public struct FieldOption<FieldName, Value> {
    /// The name of the field option.
    public let name: FieldName
    /// A binding of type `Value`.
    public let value: Binding<Value>
}

/// A tuple representing the render options for a controller.
public typealias ControllerRenderOption<FieldName, Value> = (
    field: FieldOption<FieldName, Value>,
    fieldState: FieldState,
    formState: FormState<FieldName>
) where FieldName: Hashable
