//
//  MeshTests.swift
//  Tests
//
//  Created by Per Huss on 2020-02-10.
//  Copyright © 2020 U-blox. All rights reserved.
//

import XCTest
@testable import U_blox

class MeshTests: XCTestCase {
    
    let serverStatusesWith_Temp_Amb_Acc = [("074E00340201034F00340DAAAA5500A0FE8503", (temp: 26.0, amb: 661.0, acc: (x: 0.08, y:-0.34, z:0.88))),
                                           ("074E00FCE900034F00390DAAAAF9FF04FD7402", (temp: 28.5, amb: 599.0, acc: (x:-0.01, y:-0.75, z:0.61))),
                                           ("074E0000FA00034F003C0DAAAAF4FFF9FC5102", (temp: 30.0, amb: 640.0, acc: (x:-0.01, y:-0.76, z:0.58))),
                                           ("074E00B0FE00034F003E0DAAAA71FF67FC1601", (temp: 31.0, amb: 652.0, acc: (x:-0.14, y:-0.90, z:0.27))),
                                           ("074E00F8D900034F003D0DAAAACAFF8AFDDE02", (temp: 30.5, amb: 558.0, acc: (x:-0.05, y:-0.62, z:0.72))),
        ].map { (SensorServerStatus(parameters: Data(hex:$0.0)!)!, $0.1) }
    
    
    let serverStatusesWith_Acc = [("074E00340201034F00340DAAAA5500A0FE8503", (x: 0.08, y:-0.34, z:0.88)),
        ].map { (SensorServerStatus(parameters: Data(hex:$0.0)!)!, $0.1) }
    
    
    let hslStatuses = ["000000000000": HSV(hue: 0,   saturation: 0,   brightness: 0,   alpha: 0),
                       "FFBF0000FFFF": HSV(hue: 0.00,saturation: 1.00,brightness: 0.75,alpha: 1.0),
                       "FFBF5555FFFF": HSV(hue: 0.33,saturation: 1.00,brightness: 0.75,alpha: 1.0),
                       "FFBFAAAAFFFF": HSV(hue: 0.67,saturation: 1.00,brightness: 0.75,alpha: 1.0),
                       "FFBF55D5FFFF": HSV(hue: 0.83,saturation: 1.00,brightness: 0.75,alpha: 1.0),
                       "FFBFAB2AFFFF": HSV(hue: 0.17,saturation: 1.00,brightness: 0.75,alpha: 1.0),
                       "FFBF0080FFFF": HSV(hue: 0.50,saturation: 1.00,brightness: 0.75,alpha: 1.0),
                       "FFBF00000000": HSV(hue: 0.00,saturation: 0.00,brightness: 0.75,alpha: 1.0),
        ].map { (UbloxLightHSLStatus(parameters: Data(hex:$0.0)!)!, $0.1) }
    
    override func setUp() {
    }
    
    //
    
    func testAcceleration_Temp_Amb_Acc() {
        serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in
            let a = status.acceleration!
            XCTAssertEqual(Double(a.x), value.acc.x, accuracy: 0.01)
            XCTAssertEqual(Double(a.y), value.acc.y, accuracy: 0.01)
            XCTAssertEqual(Double(a.z), value.acc.z, accuracy: 0.01)
        }
    }
    
    func testTemperature_Temp_Amb_Acc() {
        serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in
            let t = status.degreesCelsius!
            XCTAssertEqual(Double(t), value.temp, accuracy: 0.01)
        }
    }
    
    func testAmbient_Temp_Amb_Acc() {
        serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in
            let amb = status.ambientLightLux!
            XCTAssertEqual(Double(amb), value.amb, accuracy: 0.01)
        }
    }
    
    func testPressure_Temp_Amb_Acc() { serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in XCTAssertNil(status.milliBars) } }
    func testHumidity_Temp_Amb_Acc() { serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in XCTAssertNil(status.humidityPercent) } }
    
    //
    
    func testAcceleration_Acc() {
        serverStatusesWith_Acc.forEach { (status, value) in
            let a = status.acceleration!
            XCTAssertEqual(Double(a.x), value.x, accuracy: 0.01)
            XCTAssertEqual(Double(a.y), value.y, accuracy: 0.01)
            XCTAssertEqual(Double(a.z), value.z, accuracy: 0.01)
        }
    }
     
    func testTemperature_Acc() { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.degreesCelsius) } }
    func testAmbient_Acc()     { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.ambientLightLux) } }
    func testPressure_Acc()    { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.milliBars) } }
    func testHumidity_Acc()    { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.humidityPercent) } }
    
    //
    
    func testHSL() {
        hslStatuses.forEach { (status, value) in
            let color = status.color!
            XCTAssertEqual(Double(color.hue), value.hue, accuracy: 0.01)
        }
    }
    
    
    // Data storage tests
        // Node encode/decode
    
    // Communication tests
    
    // 
}

