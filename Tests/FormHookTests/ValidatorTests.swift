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
