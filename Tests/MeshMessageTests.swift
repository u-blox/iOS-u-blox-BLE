//
//  MeshTests.swift
//  Tests
//
//  Created by Per Huss on 2020-02-10.
//  Copyright © 2020 U-blox. All rights reserved.
//

import XCTest
@testable import U_blox

let accuracy = 0.005

let serverStatusesWith_Temp_Amb_Acc = [
    (status: (temp: 26.0, amb: 661.0, acc: (x: 0.08, y:-0.34, z:0.88)), data: "074E00340201034F00340DAAAA5500A0FE8503"),
    (status: (temp: 28.5, amb: 599.0, acc: (x:-0.01, y:-0.75, z:0.61)), data: "074E00FCE900034F00390DAAAAF9FF04FD7402"),
    (status: (temp: 30.0, amb: 640.0, acc: (x:-0.01, y:-0.76, z:0.58)), data: "074E0000FA00034F003C0DAAAAF4FFF9FC5102"),
    (status: (temp: 31.0, amb: 652.0, acc: (x:-0.14, y:-0.90, z:0.27)), data: "074E00B0FE00034F003E0DAAAA71FF67FC1601"),
    (status: (temp: 30.5, amb: 558.0, acc: (x:-0.05, y:-0.62, z:0.72)), data: "074E00F8D900034F003D0DAAAACAFF8AFDDE02"),
    (status: (temp: 28.0, amb: 482.0, acc: (x:-0.03, y:0.02, z:0.96)), data: "074E0048BC00034F00380DAAAAE3FF1300D603"),
    (status: (temp: 28.0, amb: 481.0, acc: (x:-0.03, y:0.02, z:0.96)), data: "074E00E4BB00034F00380DAAAAE4FF1700DA03"),
    (status: (temp: 27.0, amb: 43.0, acc: (x:0.25, y:0.28, z:0.89)), data: "074E00CC1000034F00360DAAAAFE0021018E03"),
    (status: (temp: 28.0, amb: 52.0, acc: (x:-0.14, y:0.81, z:0.81)), data: "074E00501400034F00380DAAAA72FF3D033A03"),
    (status: (temp: 27.5, amb: 7.0, acc: (x:0.03, y:0.76, z:-0.68)), data: "074E00BC0200034F00370DAAAA1B0009034AFD"),
    (status: (temp: 29.0, amb: 1.0, acc: (x:0.49, y:0.38, z:0.73)), data: "074E00640000034F003A0DAAAAF2018901EC02"),
    (status: (temp: 30.0, amb: 213.0, acc: (x:0.14, y:0.65, z:0.81)), data: "074E00345300034F003C0DAAAA8B0099023C03"),
    (status: (temp: 30.5, amb: 0.0, acc: (x:-0.02, y:-0.15, z:0.93)), data: "074E00000000034F003D0DAAAAE8FF6BFFBD03"),
    (status: (temp: 30.5, amb: 0.0, acc: (x:0.13, y:-0.09, z:-0.99)), data: "074E00000000034F003D0DAAAA8100A5FF09FC"),
    (status: (temp: 30.0, amb: 380.0, acc: (x:0.44, y:-0.11, z:1.08)), data: "074E00709400034F003C0DAAAAC30192FF5404"),
    (status: (temp: 30.5, amb: 8.0, acc: (x:-0.40, y:1.12, z:-0.46)), data: "074E00200300034F003D0DAAAA68FE780427FE"),
    (status: (temp: 30.5, amb: 167.0, acc: (x:0.16, y:-0.58, z:0.33)), data: "074E003C4100034F003D0DAAAAA800AFFD5501"),
    (status: (temp: 30.5, amb: 51.0, acc: (x:-0.84, y:-0.12, z:0.41)), data: "074E00EC1300034F003D0DAAAA9FFC88FFA401"),
    (status: (temp: 31.0, amb: 102.0, acc: (x:-0.78, y:-0.66, z:0.04)), data: "074E00D82700034F003E0DAAAAE4FC5FFD2B00"),
    (status: (temp: 30.0, amb: 30.0, acc: (x:-0.50, y:0.71, z:-0.63)), data: "074E00B80B00034F003C0DAAAAFBFDDA027FFD"),
    (status: (temp: 30.0, amb: 169.0, acc: (x:-0.83, y:-0.51, z:-0.12)), data: "074E00044200034F003C0DAAAAB2FCF4FD83FF"),
    (status: (temp: 30.0, amb: 40.0, acc: (x:-1.00, y:0.11, z:0.02)), data: "074E00A00F00034F003C0DAAAAFFFB75001500"),
    (status: (temp: 30.5, amb: 227.0, acc: (x:-0.55, y:-0.39, z:0.68)), data: "074E00AC5800034F003D0DAAAAD0FD75FEB802"),
    (status: (temp: 29.5, amb: 31.0, acc: (x:0.00, y:-0.75, z:-0.74)), data: "074E001C0C00034F003B0DAAAA040004FD0DFD"),
    (status: (temp: 30.0, amb: 326.0, acc: (x:-0.06, y:-0.52, z:0.84)), data: "074E00587F00034F003C0DAAAAC1FFF0FD5F03"),
    (status: (temp: 29.5, amb: 140.0, acc: (x:-0.34, y:-0.79, z:-0.35)), data: "074E00B03600034F003B0DAAAAA2FED5FC9AFE"),
    (status: (temp: 29.0, amb: 55.0, acc: (x:0.06, y:0.33, z:0.75)), data: "074E007C1500034F003A0DAAAA420056010503"),
    (status: (temp: 30.0, amb: 96.0, acc: (x:0.03, y:0.47, z:-0.82)), data: "074E00802500034F003C0DAAAA2300E401B4FC"),
    (status: (temp: 29.0, amb: 36.0, acc: (x:0.18, y:0.87, z:0.46)), data: "074E00100E00034F003A0DAAAAB4007B03D701"),
    (status: (temp: 29.5, amb: 69.0, acc: (x:0.01, y:0.62, z:-0.81)), data: "074E00F41A00034F003B0DAAAA06007C02C7FC"),
].map { (status: SensorServerStatus(parameters: Data(hex:$0.data)!)!,
         value: $0.status) }

let serverStatusesWith_Acc = [(acc: (x: 0.08, y:-0.34, z:0.88), data: "0DAAAA5500A0FE8503"),
                              (acc: (x:-0.01, y:-0.75, z:0.61), data: "0DAAAAF9FF04FD7402"),
                              (acc: (x:-0.01, y:-0.76, z:0.58), data: "0DAAAAF4FFF9FC5102"),
                              (acc: (x:-0.14, y:-0.90, z:0.27), data: "0DAAAA71FF67FC1601"),
                              (acc: (x:-0.05, y:-0.62, z:0.72), data: "0DAAAACAFF8AFDDE02"),
    ].map { (status: SensorServerStatus(parameters: Data(hex:$0.data)!)!,
             value: $0.acc) }

let serverStatusesBroken = [
    "74E00709400034F003",
    "D0DAAAAD0FD75EB802",
    "FF",
    "",
    "4E00100E00034F003A0DAAAAB4007B03D701074E00100E00034F003A0DAAAAB4007B03D701074E00100E00034F003A0DAAAAB4007B03D701",
    "074E00D82700034F003E0DAAAAE4FC5FFD2B",
    ].map { SensorServerStatus(parameters: Data(hex:$0)!)! }

let hslStatuses = [
    (hsl: (hue:0.00, sat:1.00, bri:0.75, a:1.00), data: "FFBF0000FFFF"),
    (hsl: (hue:0.33, sat:1.00, bri:0.75, a:1.00), data: "FFBF5555FFFF"),
    (hsl: (hue:0.67, sat:1.00, bri:0.75, a:1.00), data: "FFBFAAAAFFFF"),
    (hsl: (hue:0.83, sat:1.00, bri:0.75, a:1.00), data: "FFBF55D5FFFF"),
    (hsl: (hue:0.17, sat:1.00, bri:0.75, a:1.00), data: "FFBFAB2AFFFF"),
    (hsl: (hue:0.50, sat:1.00, bri:0.75, a:1.00), data: "FFBF0080FFFF"),
    (hsl: (hue:0.00, sat:0.00, bri:0.75, a:1.00), data: "FFBF00000000"),
    (hsl: (hue:0.00, sat:0.00, bri:0.00, a:1.00), data: "000000000000"),
    ].map { (status: UbloxLightHSLStatus(parameters: Data(hex:$0.data)!)!,
             value: $0.hsl) }

class MeshTests: XCTestCase {
    
    func testAcceleration_Temp_Amb_Acc() {
        serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in
            let a = status.acceleration!
            XCTAssertEqual(Double(a.x), value.acc.x, accuracy: accuracy)
            XCTAssertEqual(Double(a.y), value.acc.y, accuracy: accuracy)
            XCTAssertEqual(Double(a.z), value.acc.z, accuracy: accuracy)
        }
    }
    
    func testTemperature_Temp_Amb_Acc() {
        serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in
            let t = status.degreesCelsius!
            XCTAssertEqual(Double(t), value.temp, accuracy: accuracy)
        }
    }
    
    func testAmbient_Temp_Amb_Acc() {
        serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in
            let amb = status.ambientLightLux!
            XCTAssertEqual(Double(amb), value.amb, accuracy: accuracy)
        }
    }
    
    func testPressure_Temp_Amb_Acc() { serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in XCTAssertNil(status.milliBars) } }
    func testHumidity_Temp_Amb_Acc() { serverStatusesWith_Temp_Amb_Acc.forEach { (status, value) in XCTAssertNil(status.humidityPercent) } }
        
    func testAcceleration_Acc() {
        serverStatusesWith_Acc.forEach { (status, value) in
            let a = status.acceleration!
            XCTAssertEqual(Double(a.x), value.x, accuracy: accuracy)
            XCTAssertEqual(Double(a.y), value.y, accuracy: accuracy)
            XCTAssertEqual(Double(a.z), value.z, accuracy: accuracy)
        }
    }
     
    func testTemperature_Acc() { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.degreesCelsius) } }
    func testAmbient_Acc()     { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.ambientLightLux) } }
    func testPressure_Acc()    { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.milliBars) } }
    func testHumidity_Acc()    { serverStatusesWith_Acc.forEach { (status, value) in XCTAssertNil(status.humidityPercent) } }
        
    func testHSL() {
        hslStatuses.forEach { (status, value) in
            let c = status.color!
            XCTAssertEqual(Double(c.hue), value.hue, accuracy: accuracy)
            XCTAssertEqual(Double(c.saturation), value.sat, accuracy: accuracy)
            XCTAssertEqual(Double(c.brightness), value.bri, accuracy: accuracy)
            XCTAssertEqual(Double(c.alpha), value.a, accuracy: accuracy)
        }
    }
    
    func testBroken() {
        serverStatusesBroken.forEach { status in
            XCTAssertNil(status.ambientLightLux)
            XCTAssertNil(status.degreesCelsius)
            XCTAssertNil(status.humidityPercent)
            XCTAssertNil(status.milliBars)
            XCTAssertNil(status.acceleration)
            XCTAssertNil(status.color)
        }
    }
}

