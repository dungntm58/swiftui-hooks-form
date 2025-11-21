//
//  TestUtilities.swift
//  FormHookTests
//
//  Created by Robert on 28/09/2025.
//

@testable import FormHook
import Foundation
import Testing

// MARK: - Test Field Names

enum BasicTestFieldName: Hashable {
    case name
    case email
    case password
    case confirmPassword
    case age
    case bio
}

// MARK: - Mock Validators

/// A simple mock validator that always returns the configured result
class SimpleMockValidator<Value>: MockValidator<Value, Bool> {
    init(isValid: Bool, errorMessages: [String] = ["Mock validation failed"]) {
        super.init(result: isValid, messages: errorMessages)
    }
}

/// A mock validator that simulates async operations with delays
class DelayedMockValidator<Value>: Validator {
    private let isValid: Bool
    private let errorMessages: [String]
    private let delayNanoseconds: UInt64

    init(isValid: Bool, errorMessages: [String] = ["Delayed validation failed"], delayNanoseconds: UInt64 = 100_000_000) {
        self.isValid = isValid
        self.errorMessages = errorMessages
        self.delayNanoseconds = delayNanoseconds
    }

    func validate(_ value: Value) async -> Bool {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        return isValid
    }

    func computeMessage(value: Value) async -> (Bool, [String]) {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        return (isValid, isValid ? [] : errorMessages)
    }

    func generateMessage(result: Bool) -> [String] {
        result ? [] : errorMessages
    }
}

/// A validator that can be configured to throw errors for testing error handling
class ThrowingMockValidator<Value>: MockValidator<Value, Bool> {
    init(shouldThrow: Bool = true) {
        super.init(result: !shouldThrow, messages: shouldThrow ? ["Mock error occurred"] : [])
    }
}

// MARK: - Test Errors

enum TestValidationError: Error {
    case mockError
    case networkError
    case timeoutError

    var localizedDescription: String {
        switch self {
        case .mockError:
            return "Mock validation error"
        case .networkError:
            return "Network validation error"
        case .timeoutError:
            return "Validation timeout error"
        }
    }
}

// MARK: - Form Control Builder

/// A utility class for building FormControl instances for testing
class TestFormControlBuilder<FieldName: Hashable> {
    private var mode: Mode = .onSubmit
    private var reValidateMode: ReValidateMode = .onChange
    private var resolver: Resolver<FieldName>?
    private var context: Any?
    private var shouldUnregister: Bool = true
    private var shouldFocusError: Bool = true
    private var delayErrorInNanoseconds: UInt64 = 0
    private var onFocusField: (FieldName) -> Void = { _ in }

    func setMode(_ mode: Mode) -> Self {
        self.mode = mode
        return self
    }

    func setReValidateMode(_ reValidateMode: ReValidateMode) -> Self {
        self.reValidateMode = reValidateMode
        return self
    }

    func setResolver(_ resolver: @escaping Resolver<FieldName>) -> Self {
        self.resolver = resolver
        return self
    }

    func setContext(_ context: Any?) -> Self {
        self.context = context
        return self
    }

    func setShouldUnregister(_ shouldUnregister: Bool) -> Self {
        self.shouldUnregister = shouldUnregister
        return self
    }

    func setShouldFocusError(_ shouldFocusError: Bool) -> Self {
        self.shouldFocusError = shouldFocusError
        return self
    }

    func setDelayErrorInNanoseconds(_ delayErrorInNanoseconds: UInt64) -> Self {
        self.delayErrorInNanoseconds = delayErrorInNanoseconds
        return self
    }

    func setOnFocusField(_ onFocusField: @escaping (FieldName) -> Void) -> Self {
        self.onFocusField = onFocusField
        return self
    }

    func build() -> FormControl<FieldName> {
        var formState = FormState<FieldName>()
        let options = FormOption<FieldName>(
            mode: mode,
            reValidateMode: reValidateMode,
            resolver: resolver,
            context: context,
            shouldUnregister: shouldUnregister,
            shouldFocusError: shouldFocusError,
            delayErrorInNanoseconds: delayErrorInNanoseconds,
            onFocusField: onFocusField
        )

        return FormControl(options: options, formState: .init(
            get: { formState },
            set: { formState = $0 }
        ))
    }
}

// MARK: - Test Helpers

/// Helper functions for creating common test scenarios
struct TestHelpers {

    /// Creates a basic form control for testing with default settings
    static func createBasicFormControl<FieldName: Hashable>() -> FormControl<FieldName> {
        TestFormControlBuilder<FieldName>().build()
    }

    /// Creates a form control with validation disabled for testing basic functionality
    static func createFormControlWithoutValidation<FieldName: Hashable>() -> FormControl<FieldName> {
        TestFormControlBuilder<FieldName>()
            .setMode(.onChange)
            .setReValidateMode(.onChange)
            .setShouldFocusError(false)
            .build()
    }

    /// Creates a form control with delayed error display for testing async scenarios
    static func createFormControlWithDelayedErrors<FieldName: Hashable>(delayNanoseconds: UInt64 = 500_000_000) -> FormControl<FieldName> {
        TestFormControlBuilder<FieldName>()
            .setDelayErrorInNanoseconds(delayNanoseconds)
            .build()
    }

    /// Creates a sample form value for testing
    static func createSampleFormValue() -> FormValue<BasicTestFieldName> {
        [
            .name: "John Doe",
            .email: "john.doe@example.com",
            .password: "securePassword123",
            .confirmPassword: "securePassword123",
            .age: 30,
            .bio: "Software developer with 5 years of experience"
        ]
    }

    /// Creates a form state with sample data
    static func createSampleFormState() -> FormState<BasicTestFieldName> {
        let formValue = createSampleFormValue()
        return FormState<BasicTestFieldName>(
            dirtyFields: [.name, .email],
            formValues: formValue,
            defaultValues: [.name: "", .email: "", .password: "", .confirmPassword: "", .age: 0, .bio: ""],
            submissionState: .notSubmit,
            isSubmitSuccessful: false,
            submitCount: 0,
            isValid: true,
            isValidating: false,
            errors: FormError<BasicTestFieldName>()
        )
    }

    /// Waits for an async condition to be true with timeout
    static func waitFor(_ condition: @escaping () async -> Bool, timeout: TimeInterval = 2.0) async -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        return false
    }
}

// MARK: - Performance Testing Utilities

struct PerformanceTestHelpers {

    /// Measures the time taken to execute an async operation
    static func measureAsyncTime<T>(_ operation: () async throws -> T) async rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let endTime = Date()
        return (result, endTime.timeIntervalSince(startTime))
    }

    /// Creates a large number of validators for performance testing
    static func createLargeValidatorSet(count: Int) -> [any Validator<String>] {
        (0..<count).map { index in
            SimpleMockValidator<String>(isValid: index % 2 == 0, errorMessages: ["Error \(index)"])
        }
    }

    /// Creates a form control with many registered fields for stress testing
    static func createLargeFormControl(fieldCount: Int) async -> FormControl<Int> {
        let formControl = TestFormControlBuilder<Int>().build()

        for i in 0..<fieldCount {
            _ = formControl.register(name: i, options: .init(
                rules: SimpleMockValidator<String>(isValid: i % 3 != 0),
                defaultValue: "Field \(i)"
            ))
        }

        return formControl
    }
}

// MARK: - Extension Helpers

extension FormError {
    /// Helper for creating test form errors
    static func createTestError<FN>(
        for fieldName: FN,
        messages: [String] = ["Test error"]
    ) -> FormError<FN> where FN: Hashable {
        FormError<FN>(
            errorFields: [fieldName],
            messages: [fieldName: messages]
        )
    }

    /// Helper for creating multiple test errors
    static func createMultipleTestErrors<FN>(
        fields: [FN],
        messagePrefix: String = "Error for"
    ) -> FormError<FN> where FN: Hashable {
        var errorFields: Set<FN> = []
        var messages: [FN: [String]] = [:]

        for field in fields {
            errorFields.insert(field)
            messages[field] = ["\(messagePrefix) \(field)"]
        }

        return FormError<FN>(errorFields: errorFields, messages: messages)
    }
}

extension RegisterOption {
    /// Helper for creating test register options
    static func createTestOption(
        defaultValue: Value,
        isValid: Bool = true,
        errorMessages: [String] = ["Test validation failed"]
    ) -> RegisterOption<Value> {
        RegisterOption<Value>(
            rules: SimpleMockValidator<Value>(isValid: isValid, errorMessages: errorMessages),
            defaultValue: defaultValue
        )
    }
}
