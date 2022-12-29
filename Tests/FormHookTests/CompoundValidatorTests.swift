//
//  CompoundValidatorTests.swift
//  FormHookTests
//
//  Created by Robert on 27/12/2022.
//

import Foundation
import XCTest

@testable import FormHook

class CompoundValidatorTests: XCTestCase {
    func testCompoundValidatorWithAndOperator1() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound1 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssertEqual(messages1, [
            "First success",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithAndOperator2() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound2 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssertEqual(messages2, [
            "First failure"
        ])
    }
    
    func testCompoundValidatorWithAndOperator3() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["Second failure"], delayInNanoSeconds: 2000000)
        let compound3 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssertEqual(messages3, [
            "First failure"
        ])
    }
    
    func testCompoundValidatorWithAndOperator4() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["Second failure"], delayInNanoSeconds: 2000000)
        let compound4 = firstValidator.and(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages4) = await compound4.computeMessage(value: ())
        XCTAssertEqual(messages4, [
            "First success",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperator1() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound1 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssertEqual(messages1, [
            "First success"
        ])
    }
    
    func testCompoundValidatorWithOrOperator2() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound2 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssertEqual(messages2, [
            "First failure",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithOrOperator3() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["Second failure"], delayInNanoSeconds: 2000000)
        let compound3 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssertEqual(messages3, [
            "First failure",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperator4() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["Second failure"], delayInNanoSeconds: 2000000)
        let compound4 = firstValidator.or(validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages4) = await compound4.computeMessage(value: ())
        XCTAssertEqual(messages4, [
            "First success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages1() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound1 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssertEqual(messages1, [
            "First success",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages2() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound2 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssertEqual(messages2, [
            "First failure",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithAndOperatorGetAllMessages3() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["Second failure"], delayInNanoSeconds: 2000000)
        let compound3 = firstValidator.and(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssertEqual(messages3, [
            "First failure",
            "Second failure"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages1() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["First success"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound1 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages1) = await compound1.computeMessage(value: ())
        XCTAssertEqual(messages1, [
            "First success",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages2() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: true, messages: ["Second success"], delayInNanoSeconds: 2000000)
        let compound2 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages2) = await compound2.computeMessage(value: ())
        XCTAssertEqual(messages2, [
            "First failure",
            "Second success"
        ])
    }
    
    func testCompoundValidatorWithOrOperatorGetAllMessages3() async {
        let firstValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["First failure"])
        let secondValidator = MockDelayValidator<Any, Bool>(result: false, messages: ["Second failure"], delayInNanoSeconds: 2000000)
        let compound3 = firstValidator.or(shouldGetAllMessages: true, validator: secondValidator)
            .eraseToAnyValidator()
        let (_, messages3) = await compound3.computeMessage(value: ())
        XCTAssertEqual(messages3, [
            "First failure",
            "Second failure"
        ])
    }
}

struct MockDelayValidator<Value, Result>: ResultControllableValidator where Result: BoolConvertible {
    let result: Result
    let messages: [String]
    let delayInNanoSeconds: UInt64
    
    init(result: Result, messages: [String] = [], delayInNanoSeconds: UInt64 = 0) {
        self.result = result
        self.messages = messages
        self.delayInNanoSeconds = delayInNanoSeconds
    }
    
    func validate(_ value: Value) async -> Result {
        try? await Task.sleep(nanoseconds: delayInNanoSeconds)
        return result
    }
}
