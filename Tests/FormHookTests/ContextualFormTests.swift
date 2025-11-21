//
//  ContextualFormTests.swift
//  FormHookTests
//
//  Created by Robert on 28/09/2025.
//

@preconcurrency @testable import FormHook
import Foundation
import SwiftUI
import Testing

enum TestContextFieldName: Hashable {
    case username
    case email
    case password
}

@Suite("ContextualForm")
struct ContextualFormTests {

    @Suite("Type definitions")
    struct TypeDefinitionTests {

        @Test("has the correct structure")
        func hasCorrectStructure() {
            // Just test that the type exists and can be referenced
            let _: ContextualForm<Text, TestContextFieldName>.Type = ContextualForm<Text, TestContextFieldName>.self
            // Test passes by compilation
        }

        @Test("supports different content types")
        func supportsDifferentContentTypes() {
            // Test generic type constraints work
            let _: ContextualForm<VStack<Text>, TestContextFieldName>.Type = ContextualForm<VStack<Text>, TestContextFieldName>.self
            let _: ContextualForm<AnyView, TestContextFieldName>.Type = ContextualForm<AnyView, TestContextFieldName>.self
            // Test passes by compilation
        }

        @Test("enforces Hashable constraint on FieldName")
        func enforcesHashableConstraint() {
            // This test ensures that the FieldName generic is properly constrained
            // If TestContextFieldName didn't conform to Hashable, this wouldn't compile
            let _: ContextualForm<Text, TestContextFieldName>.Type = ContextualForm<Text, TestContextFieldName>.self
            // Test passes by compilation
        }
    }

    @Suite("Integration with form types")
    struct FormTypeIntegrationTests {

        @Test("works with FormControl type")
        func worksWithFormControlType() {
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

            #expect(formControl.instantFormState.formValues[.username] as? String == "test")
        }

        @Test("supports resolver functions")
        func supportsResolverFunctions() {
            func testResolver(
                values: FormValue<TestContextFieldName>,
                context: Any?,
                fieldNames: [TestContextFieldName]
            ) async -> Result<FormValue<TestContextFieldName>, FormError<TestContextFieldName>> {
                .success(values)
            }

            // Test that resolver type is compatible
            let _: Resolver<TestContextFieldName> = testResolver
            // Test passes by compilation
        }
    }

    @Suite("Error handling types")
    struct ErrorHandlingTests {

        @Test("works with FormError")
        func worksWithFormError() {
            let error = FormError<TestContextFieldName>(
                errorFields: [.username],
                messages: [.username: ["Test error"]]
            )

            #expect(error.errorFields.contains(.username))
            #expect(error[.username] == ["Test error"])
        }

        @Test("supports FormValue operations")
        func supportsFormValueOperations() {
            var formValue: FormValue<TestContextFieldName> = [:]
            formValue[.username] = "test"
            formValue[.email] = "test@example.com"

            #expect(formValue[.username] as? String == "test")
            #expect(formValue[.email] as? String == "test@example.com")
        }
    }
}
