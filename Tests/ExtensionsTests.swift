/*
 * Copyright (C) u-blox
 *
 * u-blox reserves all rights in this deliverable (documentation, software, etc.,
 * hereafter “Deliverable”).
 *
 * u-blox grants you the right to use, copy, modify and distribute the
 * Deliverable provided hereunder for any purpose without fee.
 *
 * THIS DELIVERABLE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY. IN PARTICULAR, NEITHER THE AUTHOR NOR U-BLOX MAKES ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY OF THIS
 * DELIVERABLE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 *
 * In case you provide us a feedback or make a contribution in the form of a
 * further development of the Deliverable (“Contribution”), u-blox will have the
 * same rights as granted to you, namely to use, copy, modify and distribute the
 * Contribution provided to us for any purpose without fee.
 */

import XCTest
import CoreBluetooth
@testable import U_blox

class ExtensionsTests: XCTestCase {

    func testUbloxColor() {
        XCTAssertEqual(UIColor.ublox, UIColor(red: 24/255, green: 66/255, blue: 127/255, alpha: 1))
    }

    func testParseAsVersion() {
        [
            ("", nil),
            (".", nil),
            ("..", nil),
            (".1.1", nil),
            ("1.0.", nil),
            ("1.0.0", 65536),
            ("1.0.0 33 2", 65536),
        ].forEach {
            XCTAssertEqual($0.parseAsVersion, $1, "For: \"\($0)\"")
        }
    }

    func testHexArray() {
        [
            ("", []),
            ("aa", [170]),
            ("aaa", [10, 170]),
        ].forEach {
            XCTAssertEqual($0.hexArray, $1, "For: \($0)")
        }
    }

    func testRange() {
        XCTAssertEqual("test"[0..<2], "te")
        XCTAssertEqual("test"[0..<4], "test")
        XCTAssertEqual("test"[0..<0], "")
    }

    func testDateFormatter() {
        XCTAssertEqual(DateFormatter.ublox.string(from: Date(timeIntervalSince1970: 0)), "1970-01-01 01:00:00")
    }

    func testByteArray() {
        let bytes: [Byte] = [0,15,11]
        XCTAssertEqual(Data(bytes).byteArray, bytes)
    }

    func testIsSerialPortService() {
        XCTAssertEqual(CBUUID(data: Data([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01])).isSerialPortService, true)
        XCTAssertEqual(CBUUID(data: Data([0x24, 0x56])).isSerialPortService, false)
    }

    func testCharacteristicPropertiesUbloxDescription() {
        [
            (0, ""),
            (2, "Read"),
            (5, "Broadcast WriteWithoutResponse"),
        ].forEach {
                XCTAssertEqual(CBCharacteristicProperties(rawValue: $0).ubloxDescription, $1, "For: \($0)")
        }
    }

    func testCharacteristicPropertiesSingleDescription() {
        [
            (1, "Broadcast"),
            (2, "Read"),
            (4, "WriteWithoutResponse"),
            (8, "Write"),
            (16, "Notify"),
            (32, "Indicate"),
            (64, "AuthenticatedSignedWrites"),
            (128, "ExtendedProperties"),
        ].forEach {
            XCTAssertEqual(CBCharacteristicProperties(rawValue: $0).ubloxDescription, $1, "For: \($0)")
        }
    }
}

class MockCharacteristic: CBCharacteristic {

    fileprivate let bytes: [Byte]
    fileprivate let val: Data?

    override var uuid: CBUUID {
        return CBUUID(data: Data(bytes))
    }
    override var value: Data? {
        return val
    }
    init(bytes: [Byte], value: String? = nil) {
        self.bytes = bytes
        self.val = value?.data(using: .utf8)
    }
}

extension ExtensionsTests {

    func testUbloxCharacteristic() {
        [
            ([0xff,0xd1], .ledRed),
            ([0xff,0xd2], .ledGreen),
            ([0xff,0xd3], .ledBlue),
            ([0xff,0xd4], .ledRGB),
            ([0xff,0xe1], .temperature),
            ([0x2a,0x19], .battery),
            ([0xff,0xa2], .accelerometerRange),
            ([0xff,0xa3], .accelerometerX),
            ([0xff,0xa4], .accelerometerY),
            ([0xff,0xa5], .accelerometerZ),
            ([0xff,0xb3], .gyroscopeX),
            ([0xff,0xb4], .gyroscopeY),
            ([0xff,0xb5], .gyroscopeZ),
            ([0xff,0xb6], .gyroscope),

            ([0x2a,0x23], .systemId),
            ([0x2a,0x24], .modelNumber),
            ([0x2a,0x25], .serialNumber),
            ([0x2a,0x26], .firmwareRevision),
            ([0x2a,0x27], .hardwareRevision),
            ([0x2a,0x28], .swRevision),
            ([0x2a,0x29], .manufactName),
            ([0x2a,0x2a], .regCert),

            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x02], .serialPortFlowControlMode),
            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x03], .serialPortFifo),
            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x04], .serialPortCredits),
        ].forEach {
            XCTAssertEqual(MockCharacteristic(bytes: $0).ubloxCharacteristic, $1, "For: \($0)")
        }

    }
    func testUbloxDescription() {
        let cases: [([UInt8], String)] = [
            ([0xff,0xd1], "Red LED"),
            ([0xff,0xd2], "Green LED"),
            ([0xff,0xd3], "Blue LED"),
            ([0xff,0xd4], "RGB LED"),
            ([0xff,0xe1], "Temperature"),
            ([0x2a,0x19], "Level"),
            ([0xff,0xa2], "Range"),
            ([0xff,0xa3], "X Value"),
            ([0xff,0xa4], "Y Value"),
            ([0xff,0xa5], "Z Value"),
            ([0xff,0xb3], "X Value"),
            ([0xff,0xb4], "Y Value"),
            ([0xff,0xb5], "Z Value"),
            ([0xff,0xb6], "\(MockCharacteristic(bytes: [0xff,0xb6]).uuid)"),

            ([0x2a,0x23], "System Identifier"),
            ([0x2a,0x24], "Model Number"),
            ([0x2a,0x25], "Serial Number"),
            ([0x2a,0x26], "Firmware Revision"),
            ([0x2a,0x27], "Hardware Revision"),
            ([0x2a,0x28], "Software Revision"),
            ([0x2a,0x29], "Manufacturer Name"),
            ([0x2a,0x2a], "Regulatory Certification"),

            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x02], "Flow Control Mode"),
            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x03], "FIFO"),
            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x04], "Flow Control Credits"),
        ]
        cases.forEach {
            XCTAssertEqual(MockCharacteristic(bytes: $0).ubloxDescription, $1, "For: \($0)")
        }
    }
    func testUbloxValueDescription() {
        XCTAssertEqual(MockCharacteristic(bytes: [0xff,0xd1]).ubloxValueDescription, nil)
        XCTAssertEqual(MockCharacteristic(bytes: [0xff,0xd1], value: "description").ubloxValueDescription, "11 bytes")
        XCTAssertEqual(MockCharacteristic(bytes: [0x2a,0x24]).ubloxValueDescription, nil)
        XCTAssertEqual(MockCharacteristic(bytes: [0x2a,0x24], value: "description").ubloxValueDescription, "description")
    }
}

class MockService: CBService {

    fileprivate let bytes: [Byte]

    override var uuid: CBUUID {
        return CBUUID(data: Data(bytes))
    }

    init(bytes: [Byte]) {
        self.bytes = bytes
    }
}

extension ExtensionsTests {
    func testHaveSerialPortCapability() {
        XCTAssertEqual(MockService(bytes: [0xff,0xd0]).haveSerialPortCapability, false)
        XCTAssertEqual(MockService(bytes: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01]).haveSerialPortCapability, true)
    }
    func testUbloxService() {
        [
            ([0xff,0xd0], .led),
            ([0xff,0xe0], .temperature),
            ([0x18,0x0f], .battery),
            ([0xff,0xa0], .accelerometer),
            ([0xff,0xb0], .gyroscope),
            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01], .serialPort),
            ([0x18,0x0a], .deviceInfo),
        ].forEach {
            XCTAssertEqual(MockService(bytes: $0).ubloxService, $1, "For: \($0)")
        }
    }
    func testUbloxServiceDescription() {
        [
            ([0xff,0xd0], "LED"),
            ([0xff,0xe0], "Temperature"),
            ([0x18,0x0f], "Battery"),
            ([0xff,0xa0], "Accelerometer"),
            ([0xff,0xb0], "Gyro"),
            ([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01], "Serial Port"),
            ([0x18,0x0a], "Device info"),
            ([0x18,0x1a], "SERVICE"),
        ].forEach {
            XCTAssertEqual(MockService(bytes: $0).ubloxDescription, $1, "For: \($0)")
        }
    }
}


