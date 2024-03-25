//
//  InjectedParametersClassFunctionTests.swift
//  
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import XCTest
import StitcherMacros
@testable import Stitcher

final class InjectedParametersClassFunctionTests: XCTestCase {
    
    class TestableSubject {
        
        @InjectedParameters
        func stringified(number: Int) -> String {
            return number.description
        }
        
        @InjectedParameters(ignoring: "factor")
        func multiplied(number: Int, by factor: Int) -> Int {
            return number * factor
        }
    }

    static var entry: TestFactory.Entry?
    static var number: Int = { .random(in: 1...1000) }()
    
    override class func setUp() {
        entry = TestFactory.add(number)
    }
    
    override class func tearDown() {
        guard let entry else {
            return
        }
        
        TestFactory.remove(entry: entry)
    }

    func test_parameterInjection() {
        let subject = TestableSubject()
        let result = subject.stringified()
        XCTAssert(result == Self.number.description)
    }
    
    func test_parameterInjection_ignoresParameter() {
        let subject = TestableSubject()
        let factor = Int.random(in: 1...1000)
        let result = subject.multiplied(by: factor)
        let expectedResult = Self.number * factor
        XCTAssert(result == expectedResult)
    }
}
