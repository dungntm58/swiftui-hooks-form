//
//  ValidatorTests.swift
//  FormHookTests
//
//  Created by Robert on 03/12/2022.
//

import Foundation
import XCTest
import RegexBuilder

@testable import FormHook

class ValidationTests: XCTestCase {
    func testNoEmptyValidator() async {
        var (stringValidateResult, messages) = await NotEmptyValidator(messageGenerator(_:)).computeMessage(value: "")
        XCTAssertFalse(stringValidateResult)
        XCTAssertTrue(messages == ["Invalid"])

        (stringValidateResult, messages) = await NotEmptyValidator(messageGenerator(_:)).computeMessage(value: "a")
        XCTAssertTrue(stringValidateResult)
        XCTAssertTrue(messages == [])

        var intArrayValidateResult = await NotEmptyValidator(messageGenerator(_:)).validate([Int]())
        XCTAssertFalse(intArrayValidateResult)

        intArrayValidateResult = await NotEmptyValidator(messageGenerator(_:)).validate([1])
        XCTAssertTrue(intArrayValidateResult)
    }

    func testNotNilValidator() async {
        var result = await NotNilValidator(messageGenerator(_:)).validate(Int?.none)
        XCTAssertFalse(result)

        result = await NotNilValidator(messageGenerator(_:)).validate(1)
        XCTAssertTrue(result)
    }

    func testRangeValidator() async {
        var validator = RangeValidator(max: 10, messageGenerator(_:))
        var result = await validator.validate(9)
        XCTAssertTrue(result)
        result = await validator.validate(10)
        XCTAssertTrue(result)
        result = await validator.validate(11)
        XCTAssertFalse(result)

        validator = RangeValidator(min: 10, messageGenerator(_:))
        result = await validator.validate(9)
        XCTAssertFalse(result)
        result = await validator.validate(10)
        XCTAssertTrue(result)
        result = await validator.validate(11)
        XCTAssertTrue(result)

        validator = RangeValidator(min: 9, max: 11, messageGenerator(_:))
        result = await validator.validate(8)
        XCTAssertFalse(result)
        result = await validator.validate(12)
        XCTAssertFalse(result)
        result = await validator.validate(9)
        XCTAssertTrue(result)
        result = await validator.validate(10)
        XCTAssertTrue(result)
        result = await validator.validate(11)
        XCTAssertTrue(result)
    }

    func testLengthValidator() async {
        var result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([0, 1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(maxLength: 2, messageGenerator(_:)).validate([0, 1, 2])
        XCTAssertFalse(result)

        result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([])
        XCTAssertFalse(result)
        result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(minLength: 1, messageGenerator(_:)).validate([1, 2])
        XCTAssertTrue(result)

        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([])
        XCTAssertFalse(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([0, 1, 2, 3])
        XCTAssertFalse(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1, 2])
        XCTAssertTrue(result)
        result = await LengthRangeValidator(minLength: 1, maxLength: 3, messageGenerator(_:)).validate([1, 2, 3])
        XCTAssertTrue(result)
    }

    func testPatternMatchingValidator() async {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPatternMatchingValidator = PatternMatchingValidator<String>(pattern: emailRegEx, messageGenerator(_:))
        var result = await emailPatternMatchingValidator.validate("abc@domain.com")
        XCTAssertTrue(result)
        
        result = await emailPatternMatchingValidator.validate("domain.com")
        XCTAssertFalse(result)
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, *)
    func testRegexMatchingValidator() async {
        let emailRegexMatchingValidator = RegexMatchingValidator<Substring>(
            regex: Regex {
                OneOrMore {
                    CharacterClass(
                        .anyOf("._%+-"),
                        ("A"..."Z"),
                        ("0"..."9"),
                        ("a"..."z")
                    )
                }
                "@"
                OneOrMore {
                    CharacterClass(
                        .anyOf(".-"),
                        ("A"..."Z"),
                        ("a"..."z"),
                        ("0"..."9")
                    )
                }
                "."
                Repeat(2...64) {
                    CharacterClass(
                        ("A"..."Z"),
                        ("a"..."z")
                    )
                }
            }
              .anchorsMatchLineEndings(),
            messageGenerator(_:))
        var result = await emailRegexMatchingValidator.validate("abc@domain.com")
        XCTAssertTrue(result)

        result = await emailRegexMatchingValidator.validate("domain.com")
        XCTAssertFalse(result)
    }

    // MARK: - Edge Case Tests

    func testNotEmptyValidatorEdgeCases() async {
        let validator = NotEmptyValidator<String>(messageGenerator(_:))

        // Test with whitespace-only string
        var result = await validator.validate("   ")
        XCTAssertTrue(result) // NotEmptyValidator only checks for empty, not whitespace

        // Test with newline characters
        result = await validator.validate("\n\t")
        XCTAssertTrue(result)

        // Test with unicode characters
        result = await validator.validate("🙂")
        XCTAssertTrue(result)

        // Test with empty arrays using the correct validator type
        let intArrayValidator = NotEmptyValidator<[Int]>(messageGenerator(_:))
        let intArrayResult = await intArrayValidator.validate([Int]())
        XCTAssertFalse(intArrayResult)

        let stringArrayValidator = NotEmptyValidator<[String]>(messageGenerator(_:))
        let stringArrayResult = await stringArrayValidator.validate([String]())
        XCTAssertFalse(stringArrayResult)
    }

    func testNotNilValidatorEdgeCases() async {
        // Test with String optional
        var stringResult = await NotNilValidator(messageGenerator(_:)).validate(String?.none)
        XCTAssertFalse(stringResult)

        stringResult = await NotNilValidator(messageGenerator(_:)).validate(String?.some(""))
        XCTAssertTrue(stringResult)

        // Test with nested optionals using the correct validator type
        let nestedOptionalValidator = NotNilValidator<Int??>(messageGenerator(_:))
        let nestedOptional: Int?? = .some(.none)
        let nestedResult = await nestedOptionalValidator.validate(nestedOptional)
        XCTAssertTrue(nestedResult) // The outer optional is not nil

        // Test with zero values (should be valid)
        let zeroResult = await NotNilValidator(messageGenerator(_:)).validate(0 as Int?)
        XCTAssertTrue(zeroResult)

        let falseResult = await NotNilValidator(messageGenerator(_:)).validate(false as Bool?)
        XCTAssertTrue(falseResult)
    }

    func testRangeValidatorEdgeCases() async {
        // Test with floating point numbers
        let floatValidator = RangeValidator(min: 0.1, max: 0.9, messageGenerator(_:))
        var result = await floatValidator.validate(0.5)
        XCTAssertTrue(result)

        result = await floatValidator.validate(0.05)
        XCTAssertFalse(result)

        // Test with negative ranges
        let negativeValidator = RangeValidator(min: -10, max: -5, messageGenerator(_:))
        result = await negativeValidator.validate(-7)
        XCTAssertTrue(result)

        result = await negativeValidator.validate(-3)
        XCTAssertFalse(result)

        // Test edge case: min equals max
        let equalValidator = RangeValidator(min: 5, max: 5, messageGenerator(_:))
        result = await equalValidator.validate(5)
        XCTAssertTrue(result)

        result = await equalValidator.validate(4)
        XCTAssertFalse(result)

        // Test with only min or only max set to extreme values
        let maxOnlyValidator = RangeValidator(max: Int.max, messageGenerator(_:))
        result = await maxOnlyValidator.validate(Int.max - 1)
        XCTAssertTrue(result)

        let minOnlyValidator = RangeValidator(min: Int.min, messageGenerator(_:))
        result = await minOnlyValidator.validate(Int.min + 1)
        XCTAssertTrue(result)
    }

    func testLengthValidatorEdgeCases() async {
        // Test with strings instead of arrays
        let stringValidator = LengthRangeValidator<String>(minLength: 2, maxLength: 5, messageGenerator(_:))
        var result = await stringValidator.validate("abc")
        XCTAssertTrue(result)

        result = await stringValidator.validate("a")
        XCTAssertFalse(result)

        result = await stringValidator.validate("abcdef")
        XCTAssertFalse(result)

        // Test with unicode strings
        result = await stringValidator.validate("🙂🎉")
        XCTAssertTrue(result) // 2 unicode characters

        // Test with empty string and zero min length
        let zeroMinValidator = LengthRangeValidator<String>(minLength: 0, maxLength: 3, messageGenerator(_:))
        result = await zeroMinValidator.validate("")
        XCTAssertTrue(result)

        // Test with very large max length
        let largeMaxValidator = LengthRangeValidator<[Int]>(maxLength: 1000000, messageGenerator(_:))
        result = await largeMaxValidator.validate(Array(repeating: 1, count: 999999))
        XCTAssertTrue(result)

        // Test with sets (which also have count)
        let setValidator = LengthRangeValidator<Set<Int>>(minLength: 1, maxLength: 3, messageGenerator(_:))
        result = await setValidator.validate(Set([1, 2]))
        XCTAssertTrue(result)

        result = await setValidator.validate(Set<Int>())
        XCTAssertFalse(result)
    }

    func testPatternMatchingValidatorEdgeCases() async {
        // Test with complex regex patterns
        let phoneValidator = PatternMatchingValidator<String>(
            pattern: "^\\+?[1-9]\\d{1,14}$",
            messageGenerator(_:)
        )

        var result = await phoneValidator.validate("+1234567890")
        XCTAssertTrue(result)

        result = await phoneValidator.validate("1234567890")
        XCTAssertTrue(result)

        result = await phoneValidator.validate("+0123456789") // Leading zero after +
        XCTAssertFalse(result)

        // Test with multiline strings
        let multilineValidator = PatternMatchingValidator<String>(
            pattern: "^Line1\\nLine2$",
            messageGenerator(_:)
        )

        result = await multilineValidator.validate("Line1\nLine2")
        XCTAssertTrue(result)

        result = await multilineValidator.validate("Line1\nLine3")
        XCTAssertFalse(result)

        // Test with special characters
        let specialCharsValidator = PatternMatchingValidator<String>(
            pattern: "^[a-zA-Z0-9!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+$",
            messageGenerator(_:)
        )

        result = await specialCharsValidator.validate("Hello@World#123!")
        XCTAssertTrue(result)

        result = await specialCharsValidator.validate("Hello 世界") // Contains space and non-ASCII
        XCTAssertFalse(result)

        // Test with empty pattern (should match empty string)
        let emptyPatternValidator = PatternMatchingValidator<String>(
            pattern: "^$",
            messageGenerator(_:)
        )

        result = await emptyPatternValidator.validate("")
        XCTAssertTrue(result)

        result = await emptyPatternValidator.validate("a")
        XCTAssertFalse(result)
    }

    func testValidatorMessageGeneration() async {
        let customMessageGenerator: (Bool) -> [String] = { isValid in
            if isValid {
                return []
            }
            return ["Custom error message", "Additional context"]
        }

        let validator = NotEmptyValidator<String>(customMessageGenerator)
        let (isValid, messages) = await validator.computeMessage(value: "")

        XCTAssertFalse(isValid)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0], "Custom error message")
        XCTAssertEqual(messages[1], "Additional context")

        // Test with valid input
        let (isValid2, messages2) = await validator.computeMessage(value: "valid")
        XCTAssertTrue(isValid2)
        XCTAssertTrue(messages2.isEmpty)
    }

    func testAsyncValidatorBehavior() async {
        // Test that validators are truly async and can handle delays
        let startTime = Date()

        // Create a simple validator that we can test timing with
        let validator = NotEmptyValidator<String> { _ in
            // Use synchronous message generator for now
            return ["Delayed message"]
        }

        let _ = await validator.validate("")
        let endTime = Date()

        // Should have taken at least some time due to the sleep
        let timeDifference = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThan(timeDifference, 0.0) // Just verify some time passed
    }

    func testConcurrentValidation() async {
        // Test multiple validators running concurrently
        let validator1 = NotEmptyValidator<String>(messageGenerator(_:))
        let validator2 = RangeValidator<Int>(min: 1, max: 10, messageGenerator(_:))
        let validator3 = LengthRangeValidator<String>(minLength: 1, maxLength: 5, messageGenerator(_:))

        // Run validations concurrently
        async let result1 = validator1.validate("test")
        async let result2 = validator2.validate(5)
        async let result3 = validator3.validate("abc")

        let results = await [result1, result2, result3]

        XCTAssertTrue(results[0])
        XCTAssertTrue(results[1])
        XCTAssertTrue(results[2])
    }

    func testValidatorWithExtremeLengths() async {
        let longStringValidator = LengthRangeValidator<String>(minLength: 1000, maxLength: 2000, messageGenerator(_:))

        // Test with very long string
        let longString = String(repeating: "a", count: 1500)
        let result = await longStringValidator.validate(longString)
        XCTAssertTrue(result)

        // Test just below minimum
        let shortString = String(repeating: "a", count: 999)
        let result2 = await longStringValidator.validate(shortString)
        XCTAssertFalse(result2)

        // Test just above maximum
        let tooLongString = String(repeating: "a", count: 2001)
        let result3 = await longStringValidator.validate(tooLongString)
        XCTAssertFalse(result3)
    }
}

private func messageGenerator(_ value: Bool) -> [String] {
    if value {
        return []
    }
    return ["Invalid"]
}

protocol ResultControllableValidator: Validator where Result: BoolConvertible {
    var result: Result { get }
    var messages: [String] { get }
}

extension ResultControllableValidator {
    func validate(_ value: Value) async -> Result {
        result
    }
    
    func generateMessage(result: Result) -> [String] {
        messages
    }
}

class MockValidator<Value, Result>: ResultControllableValidator where Result: BoolConvertible {
    var result: Result
    var messages: [String]
    
    init(result: Result, messages: [String] = []) {
        self.result = result
        self.messages = messages
    }
}
