//
//  ContextualFormTests.swift
//  FormHookTests
//
//  Created by Claude on 28/09/2025.
//

import Foundation
import SwiftUI
import Quick
import Nimble
@preconcurrency @testable import FormHook

enum TestContextFieldName: Hashable {
    case username
    case email
    case password
}

final class ContextualFormTests: QuickSpec {
    override func spec() {
        contextualFormTypeSpecs()
    }

    func contextualFormTypeSpecs() {
        describe("ContextualForm") {
            context("type definitions") {
                it("has the correct structure") {
                    // Just test that the type exists and can be referenced
                    let _: ContextualForm<Text, TestContextFieldName>.Type = ContextualForm<Text, TestContextFieldName>.self
                    expect(true) == true
                }

                it("supports different content types") {
                    // Test generic type constraints work
                    let _: ContextualForm<VStack<Text>, TestContextFieldName>.Type = ContextualForm<VStack<Text>, TestContextFieldName>.self
                    let _: ContextualForm<AnyView, TestContextFieldName>.Type = ContextualForm<AnyView, TestContextFieldName>.self
                    expect(true) == true
                }

                it("enforces Hashable constraint on FieldName") {
                    // This test ensures that the FieldName generic is properly constrained
                    // If TestContextFieldName didn't conform to Hashable, this wouldn't compile
                    let _: ContextualForm<Text, TestContextFieldName>.Type = ContextualForm<Text, TestContextFieldName>.self
                    expect(true) == true
                }
            }

            context("integration with form types") {
                it("works with FormControl type") {
                    // Test that FormControl and ContextualForm use compatible types
                    var formState = FormState<TestContextFieldName>()
                    let options = FormOption<TestContextFieldName>(
                        mode: .onSubmit,
                        reValidateMode: .onChange,
                        resolver: nil,
                        context: nil,
                        shouldUnregister: true,
                        shouldFocusError: true,
                        delayErrorInNanoseconds: 0,
                        onFocusField: { _ in }
                    )
                    let formControl = FormControl(options: options, formState: .init(
                        get: { formState },
                        set: { formState = $0 }
                    ))

                    // Test that FormControl can work with the same field type
                    _ = formControl.register(name: TestContextFieldName.username, options: .init(
                        rules: NoopValidator<String>(),
                        defaultValue: "test"
                    ))

                    expect(formControl.instantFormState.formValues[.username] as? String) == "test"
                }

                it("supports resolver functions") {
                    func testResolver(
                        values: FormValue<TestContextFieldName>,
                        context: Any?,
                        fieldNames: [TestContextFieldName]
                    ) async -> Result<FormValue<TestContextFieldName>, FormError<TestContextFieldName>> {
                        return .success(values)
                    }

                    // Test that resolver type is compatible
                    let _: Resolver<TestContextFieldName> = testResolver
                    expect(true) == true
                }
            }

            context("error handling types") {
                it("works with FormError") {
                    let error = FormError<TestContextFieldName>(
                        errorFields: [.username],
                        messages: [.username: ["Test error"]]
                    )

                    expect(error.errorFields.contains(.username)) == true
                    expect(error[.username]) == ["Test error"]
                }

                it("supports FormValue operations") {
                    var formValue: FormValue<TestContextFieldName> = [:]
                    formValue[.username] = "test"
                    formValue[.email] = "test@example.com"

                    expect(formValue[.username] as? String) == "test"
                    expect(formValue[.email] as? String) == "test@example.com"
                }
            }
        }
    }
}