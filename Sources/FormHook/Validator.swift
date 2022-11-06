//
//  Validator.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation

public protocol Validator {
    associatedtype Value

    func validate(_ value: Value) -> Bool
}

extension Validator {
    public func eraseToAnyValidator() -> AnyValidator {
        .init(self)
    }
}

public struct AnyValidator: Validator {
    fileprivate let box: AnyValidatorBox

    init<V>(_ validator: V) where V: Validator {
        if let v = validator as? AnyValidator {
            self = v
        } else {
            self.box = Box(validator)
        }
    }

    public func validate(_ value: Any) -> Bool {
        box.validate(value)
    }
}

private protocol AnyValidatorBox {
    func validate(_ value: Any) -> Bool
}

private struct Box<Base>: AnyValidatorBox where Base: Validator {
    let base: Base

    init(_ base: Base) {
        self.base = base
    }

    func validate(_ value: Any) -> Bool {
        base.validate(value as! Base.Value)
    }
}
