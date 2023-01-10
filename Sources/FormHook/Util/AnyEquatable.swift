//
//  AnyEquatable.swift
//  swiftui-hooks-form
//
//  Created by Robert on 10/11/2022.
//

import Foundation

private protocol Flattenable {
    func flattened() -> Any?
}

extension Optional: Flattenable {
    func flattened() -> Any? {
        switch self {
        case .some(let x as Flattenable): return x.flattened()
        case .some(let x): return x
        case .none: return nil
        }
    }
}

private extension Equatable {
    func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

func areEqual(first: Any?, second: Any?) -> Bool {
    guard let first, let second else {
        return false
    }
    if let first = first as? any Equatable, let second = second as? any Equatable {
        return first.isEqual(second)
    }
    if first as AnyObject === second as AnyObject {
        return true
    }
    guard let first = first as? [AnyHashable: Any], let second = second as? [AnyHashable: Any] else {
        return false
    }
    guard first.count == second.count else {
        return false
    }
    for (key, value) in first {
        guard areEqual(first: value, second: second[key]) else {
            return false
        }
    }
    return true
}

struct AnyEquatable: Equatable {
    static func == (lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
        areEqual(first: lhs.base, second: rhs.base)
    }

    let base: Any?

    init(_ base: Any?) {
        if let obj = base as? AnyEquatable {
            self = obj
        } else {
            self.base = base
        }
    }
}
