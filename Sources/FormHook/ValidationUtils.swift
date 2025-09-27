//
//  ValidationUtils.swift
//  swiftui-hooks-form
//
//  Created by Robert on 06/11/2022.
//

import Foundation
import SwiftUI
import Hooks

// MARK: - Validation Utilities

extension FormControl {
    /// Validates multiple fields concurrently and returns the overall validity and errors.
    /// - Parameters:
    ///   - fieldNames: The names of the fields to validate.
    ///   - shouldStopOnFirstError: Whether to stop validation when the first error is encountered.
    /// - Returns: A tuple containing the overall validity and form errors.
    func validateFields(
        fieldNames: [FieldName],
        shouldStopOnFirstError: Bool = false
    ) async -> (isValid: Bool, errors: FormError<FieldName>) {
        return await withTaskGroup(of: KeyValidationResult.self) { group in
            var errorFields: Set<FieldName> = .init()
            var messages: [FieldName: [String]] = [:]
            var isOverallValid = true

            for name in fieldNames {
                guard let field = fields[name] else {
                    continue
                }
                group.addTask {
                    let (isValid, messages) = await field.computeMessages()
                    return KeyValidationResult(key: name, isValid: isValid, messages: messages)
                }
            }

            for await keyResult in group {
                messages[keyResult.key] = keyResult.messages
                if !keyResult.isValid {
                    errorFields.insert(keyResult.key)
                    isOverallValid = false
                    if shouldStopOnFirstError {
                        group.cancelAll()
                        break
                    }
                }
            }

            return (isOverallValid, FormError(errorFields: errorFields, messages: messages))
        }
    }

    /// Validates all registered fields concurrently and returns the overall validity and errors.
    /// - Parameter shouldStopOnFirstError: Whether to stop validation when the first error is encountered.
    /// - Returns: A tuple containing the overall validity and form errors.
    func validateAllFields(shouldStopOnFirstError: Bool = false) async -> (isValid: Bool, errors: FormError<FieldName>) {
        return await validateFields(fieldNames: Array(fields.keys), shouldStopOnFirstError: shouldStopOnFirstError)
    }

    /// Validates fields with existing errors concurrently for re-validation scenarios.
    /// - Returns: A tuple containing the overall validity and form errors.
    func revalidateErrorFields() async -> (isValid: Bool, errors: FormError<FieldName>) {
        let errorFieldNames = Array(fields.keys.filter(instantFormState.errors.errorFields.contains))
        return await validateFields(fieldNames: errorFieldNames)
    }
}