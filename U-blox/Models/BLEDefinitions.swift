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

import CoreBluetooth

enum ChatState {
    case notLoaded, disappeared, appearedIdle, appearedWaitTx, appearedNoConnectPeripheral
}

enum UbloxNotificationTypes: String {
    case peripheralUpdated = "UbloxNotificationPeripheralUpdated"
    case peripheralConnected = "UbloxNotificationPeripheralConnected"
    case peripheralConnectionFailed = "UbloxNotificationPeripheralConnectionFailed"
    case characteristicValueUpdated = "UbloxNotificationCharacteristicValueUpdated"
    case serviceDiscovered = "UbloxNotificationServiceDiscovered"
    case peripheralDisconnected = "UbloxNotificationPeripheralDisconnected"
    case peripheralListChanged = "UbloxNotificationPeripheralListChanged"
    case rssiUpdated = "UbloxNotificationRSSIUpdated"
    case serialPortMessage = "UbloxNotificationSerialPortMessage"

    var notificationName: NSNotification.Name {
        return NSNotification.Name(rawValue: self.rawValue)
    }
}

struct UbloxDictionaryKeys {
    static let uuid = "UUID"
    static let rssi = "RSSI"
    static let characteristic = "Characteristic"
    static let ubloxCharacteristic = "UbloxCharacteristic"
    static let ubloxPeripheral = "UbloxPeripheral"
    static let peripheral = "Peripheral"
    static let name = "Name"
    static let message = "Message"
    static let writeState = "WriteState"
}

typealias Byte = UInt8
struct Uuid {
    var value: [Byte] = []
}

extension Uuid: Equatable {
    public static func ==(lhs: Uuid, rhs: Uuid) -> Bool {
        guard lhs.value.count == rhs.value.count else {
            return false
        }
        for index in 0..<lhs.value.count {
            if lhs.value[index] != rhs.value[index] {
                return false
            }
        }
        return true
    }
}

extension Uuid: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Byte...) {
        elements.forEach { value.append($0) }
    }
}

protocol CBUUIDRepresentable {
    var rawValue: Uuid { get }
    var cbUuid: CBUUID { get }
}
extension CBUUIDRepresentable {
    var cbUuid: CBUUID {
        return CBUUID(data: Data(bytes: rawValue.value))
    }
}

enum UbloxCharacteristic: CBUUIDRepresentable {
    case ledRed
    case ledGreen
    case ledBlue
    case ledRGB
    case temperature
    case battery
    case accelerometerRange
    case accelerometerX
    case accelerometerY
    case accelerometerZ
    case gyroscopeX
    case gyroscopeY
    case gyroscopeZ
    case gyroscope

    case systemId
    case modelNumber
    case serialNumber
    case firmwareRevision
    case hardwareRevision
    case swRevision
    case manufactName
    case regCert

    case serialPortFlowControlMode
    case serialPortFifo
    case serialPortCredits
}

extension UbloxCharacteristic: RawRepresentable {
    init?(rawValue: Uuid) {
        switch rawValue {
        case Uuid(value: [0xff,0xd1]) : self = .ledRed
        case Uuid(value: [0xff,0xd2]) : self = .ledGreen
        case Uuid(value: [0xff,0xd3]) : self = .ledBlue
        case Uuid(value: [0xff,0xd4]) : self = .ledRGB
        case Uuid(value: [0xff,0xe1]) : self = .temperature
        case Uuid(value: [0x2a,0x19]) : self = .battery
        case Uuid(value: [0xff,0xa2]) : self = .accelerometerRange
        case Uuid(value: [0xff,0xa3]) : self = .accelerometerX
        case Uuid(value: [0xff,0xa4]) : self = .accelerometerY
        case Uuid(value: [0xff,0xa5]) : self = .accelerometerZ
        case Uuid(value: [0xff,0xb3]) : self = .gyroscopeX
        case Uuid(value: [0xff,0xb4]) : self = .gyroscopeY
        case Uuid(value: [0xff,0xb5]) : self = .gyroscopeZ
        case Uuid(value: [0xff,0xb6]) : self = .gyroscope

        case Uuid(value: [0x2a,0x23]) : self = .systemId
        case Uuid(value: [0x2a,0x24]) : self = .modelNumber
        case Uuid(value: [0x2a,0x25]) : self = .serialNumber
        case Uuid(value: [0x2a,0x26]) : self = .firmwareRevision
        case Uuid(value: [0x2a,0x27]) : self = .hardwareRevision
        case Uuid(value: [0x2a,0x28]) : self = .swRevision
        case Uuid(value: [0x2a,0x29]) : self = .manufactName
        case Uuid(value: [0x2a,0x2a]) : self = .regCert

        case Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x02]) : self = .serialPortFlowControlMode
        case Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x03]) : self = .serialPortFifo
        case Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x04]) : self = .serialPortCredits
        default: return nil
        }
    }

    var rawValue: Uuid {
        switch self {
        case .ledRed: return Uuid(value: [0xff,0xd1])
        case .ledGreen: return Uuid(value: [0xff,0xd2])
        case .ledBlue: return Uuid(value: [0xff,0xd3])
        case .ledRGB: return Uuid(value: [0xff,0xd4])
        case .temperature: return Uuid(value: [0xff,0xe1])
        case .battery: return Uuid(value: [0x2a,0x19])
        case .accelerometerRange: return Uuid(value: [0xff,0xa2])
        case .accelerometerX: return Uuid(value: [0xff,0xa3])
        case .accelerometerY: return Uuid(value: [0xff,0xa4])
        case .accelerometerZ: return Uuid(value: [0xff,0xa5])
        case .gyroscopeX: return Uuid(value: [0xff,0xb3])
        case .gyroscopeY: return Uuid(value: [0xff,0xb4])
        case .gyroscopeZ: return Uuid(value: [0xff,0xb5])
        case .gyroscope: return Uuid(value: [0xff,0xb6])

        case .systemId: return Uuid(value: [0x2a,0x23])
        case .modelNumber: return Uuid(value: [0x2a,0x24])
        case .serialNumber: return Uuid(value: [0x2a,0x25])
        case .firmwareRevision: return Uuid(value: [0x2a,0x26])
        case .hardwareRevision: return Uuid(value: [0x2a,0x27])
        case .swRevision: return Uuid(value: [0x2a,0x28])
        case .manufactName: return Uuid(value: [0x2a,0x29])
        case .regCert: return Uuid(value: [0x2a,0x2a])

        case .serialPortFlowControlMode: return Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x02])
        case .serialPortFifo: return Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x03])
        case .serialPortCredits: return Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x04])
        }
    }
}

enum UbloxService: CBUUIDRepresentable {
    case led
    case temperature
    case battery
    case accelerometer
    case gyroscope
    case serialPort
    case deviceInfo

    case immediateAlert
    case linkLoss
    case txPower
    case currentTime
    case refTimeUpdate
    case nextDstChange
    case glucose
    case healthTherm
    case networkAvail
    case heartRate
    case phoneAlertStatus
    case bloodPressure
    case alertNotification
    case humanIntDevice
    case scanParameters
    case runSpeedCadence
}
extension UbloxService: RawRepresentable {
    init?(rawValue: Uuid) {
        switch rawValue {
        case Uuid(value: [0xff,0xd0]) : self = .led
        case Uuid(value: [0xff,0xe0]) : self = .temperature
        case Uuid(value: [0x18,0x0f]) : self = .battery
        case Uuid(value: [0xff,0xa0]) : self = .accelerometer
        case Uuid(value: [0xff,0xb0]) : self = .gyroscope
        case Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01]) : self = .serialPort
        case Uuid(value: [0x18,0x0a]) : self = .deviceInfo

        case Uuid(value: [0x18,0x02]) : self = .immediateAlert
        case Uuid(value: [0x18,0x03]) : self = .linkLoss
        case Uuid(value: [0x18,0x04]) : self = .txPower
        case Uuid(value: [0x18,0x05]) : self = .currentTime
        case Uuid(value: [0x18,0x06]) : self = .refTimeUpdate
        case Uuid(value: [0x18,0x07]) : self = .nextDstChange
        case Uuid(value: [0x18,0x08]) : self = .glucose
        case Uuid(value: [0x18,0x09]) : self = .healthTherm
        case Uuid(value: [0x18,0x0b]) : self = .networkAvail
        case Uuid(value: [0x18,0x0d]) : self = .heartRate
        case Uuid(value: [0x18,0x0e]) : self = .phoneAlertStatus
        case Uuid(value: [0x18,0x10]) : self = .bloodPressure
        case Uuid(value: [0x18,0x11]) : self = .alertNotification
        case Uuid(value: [0x18,0x12]) : self = .humanIntDevice
        case Uuid(value: [0x18,0x13]) : self = .scanParameters
        case Uuid(value: [0x18,0x14]) : self = .runSpeedCadence
        default: return nil
        }
    }

    var rawValue: Uuid {
        switch self {
        case .led: return Uuid(value: [0xff,0xd0])
        case .temperature: return Uuid(value: [0xff,0xe0])
        case .battery: return Uuid(value: [0x18,0x0f])
        case .accelerometer: return Uuid(value: [0xff,0xa0])
        case .gyroscope: return Uuid(value: [0xff,0xb0])
        case .serialPort: return Uuid(value: [0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01])
        case .deviceInfo: return Uuid(value: [0xff,0x0a])

        case .immediateAlert: return Uuid(value: [0x18,0x02])
        case .linkLoss: return Uuid(value: [0x18,0x03])
        case .txPower: return Uuid(value: [0x18,0x04])
        case .currentTime: return Uuid(value: [0x18,0x05])
        case .refTimeUpdate: return Uuid(value: [0x18,0x06])
        case .nextDstChange: return Uuid(value: [0x18,0x07])
        case .glucose: return Uuid(value: [0x18,0x08])
        case .healthTherm: return Uuid(value: [0x18,0x09])
        case .networkAvail: return Uuid(value: [0x18,0x0b])
        case .heartRate: return Uuid(value: [0x18,0x0d])
        case .phoneAlertStatus: return Uuid(value: [0x18,0x0e])
        case .bloodPressure: return Uuid(value: [0x18,0x10])
        case .alertNotification: return Uuid(value: [0x18,0x11])
        case .humanIntDevice: return Uuid(value: [0x18,0x12])
        case .scanParameters: return Uuid(value: [0x18,0x13])
        case .runSpeedCadence: return Uuid(value: [0x18,0x14])
        }
    }
}

struct SerialPortHelper {

    static var supportedCharacteristics: [UbloxCharacteristic] {
        return supportedServices.reduce([]) { (result, ubloxService) -> [UbloxCharacteristic] in
            return result + supportedCharacteristics(for: ubloxService)
        }
    }

    static var supportedServices: [UbloxService] {
        return [.serialPort]
    }

    static func supportedCharacteristics(for service: UbloxService) -> [UbloxCharacteristic] {
        switch service {
        case .serialPort:
            return [.serialPortFifo, .serialPortCredits]
        default:
            return []
        }
    }
}


