//
//  ServerMessageParserTests.swift
//  u-blox BLETests
//
//  Created by Nowaczyk Axel on 15/02/2018.
//  Copyright © 2018 U-blox. All rights reserved.
//

import XCTest
@testable import U_blox

class ServerMessageParserTests: XCTestCase {
    
    func testHelp() {
        XCTAssert(ServerResponseParser.parse(message: "help") == .help(commandName: nil), "")
        XCTAssert(ServerResponseParser.parse(message: "help\n") == .help(commandName: nil), "")
    }

    func testTest() {
        XCTAssert(ServerResponseParser.parse(message: "test mock") == ServerResponseType.test(testSettings: TestSettings(showTx: false, showRx: false, testingCredits: false, packageSize: 20, byteCount: nil, deviceName: "mock")), "")
    }

    func testUnknown() {
        XCTAssert(ServerResponseParser.parse(message: "fsdfsdfsfsd") == .unknown, "")
    }

    func testServerMessageTypeEquail() {
        XCTAssert(.unknown == .unknown, "")
        XCTAssert(.help(commandName: nil) == .help(commandName: nil), "")
        XCTAssert(.test(testSettings: TestSettings()) == .test(testSettings: TestSettings()), "")
        XCTAssertFalse(ServerResponseType.test(testSettings: TestSettings(showTx: false, showRx: false, testingCredits: false, packageSize: 20, byteCount: nil, deviceName: "")) == ServerResponseType.test(testSettings: TestSettings(showTx: false, showRx: false, testingCredits: false, packageSize: 20, byteCount: 40, deviceName: "")), "")
        XCTAssertFalse(.help(commandName: nil) == .unknown, "")
    }
    
}
extension ServerResponseType: Equatable {
    static public func ==(lhs: ServerResponseType, rhs: ServerResponseType) -> Bool {
        switch (lhs, rhs) {
        case (.help, .help), (.unknown, .unknown):
            return true
            case (.test(let testSettingsLHS), .test(let testSettingsRHS)):
                return testSettingsLHS.byteCount == testSettingsRHS.byteCount &&
                       testSettingsLHS.packageSize == testSettingsRHS.packageSize &&
                       testSettingsLHS.testingCredits == testSettingsRHS.testingCredits
        default:
            return false
        }
    }
}

