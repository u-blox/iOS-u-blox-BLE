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

import Foundation
import UIKit
import CoreBluetooth

extension UIColor {
    open class var ublox: UIColor {
        return UIColor(red: 24/255, green: 66/255, blue: 127/255, alpha: 1)
    }
}

extension String {
    var parseAsVersion: Int? {
        let versionArray = self.components(separatedBy: ".")
        guard versionArray.count == 3 else {
                return nil
        }
        let subminorVersionArray = versionArray[2].components(separatedBy: " ")
        guard subminorVersionArray.count > 0,
            let major = Int(versionArray[0]),
            let minor = Int(versionArray[1]),
            let subminor = Int(subminorVersionArray[0]) else {
                return nil
        }
        return ((major << 16) | (minor << 8) | (subminor))
    }
    var hexArray: [UInt32] {
        var hexStrings: [String] = []

        var i = 0
        while i < self.count {
            if i == 0 && self.count % 2 != 0 {
                hexStrings.append(self[i..<i+1])
                i += 1
            } else {
                hexStrings.append(self[i..<i+2])
                i += 2
            }
        }

        return hexStrings.map { string -> UInt32? in
            let scanner = Scanner(string: string)
            var value: UInt32 = 0
            let valueConverted = scanner.scanHexInt32(UnsafeMutablePointer<UInt32>(&value))
            return valueConverted ? value : nil
        }.filter { $0 != nil } as! [UInt32]
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension DateFormatter {
    static var ublox: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
}

extension Data {
    var byteArray: [Byte] {
        let bufferPointer = UnsafeBufferPointer(start: (self as NSData).bytes.assumingMemoryBound(to: Byte.self), count: count)
        return Array(bufferPointer)
    }
}

extension NotificationCenter {
    func post(notificationType aType: UbloxNotificationTypes, object anObject: Any?, userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        post(name: aType.notificationName, object: anObject, userInfo: aUserInfo)
    }

    func addObserver(_ observer: Any, selector aSelector: Selector, type aType: UbloxNotificationTypes?, object anObject: Any?) {
        addObserver(observer, selector: aSelector, name: aType?.notificationName, object: anObject)
    }

    @available(iOS 4.0, *)
    func addObserver(forType type: UbloxNotificationTypes?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Swift.Void) {
        addObserver(forName: type?.notificationName, object: obj, queue: queue, using: block)
    }
}

extension CBUUID {
    var isSerialPortService: Bool {
        guard let ubloxService = UbloxService(rawValue: Uuid(value: data.byteArray)),
              SerialPortHelper.supportedServices.contains(ubloxService) else {
                return false
        }
        return true
    }
}

extension CBCharacteristicProperties {
    public var ubloxDescription: String {
        return CBCharacteristicProperties.allValues.filter(contains).map{ $0.singleDescription }.joined(separator: " ")
    }
    private var singleDescription: String {
        switch self {
        case .broadcast: return "Broadcast"
        case .read: return "Read"
        case .writeWithoutResponse: return "WriteWithoutResponse"
        case .write: return "Write"
        case .notify: return "Notify"
        case .indicate: return "Indicate"
        case .authenticatedSignedWrites: return "AuthenticatedSignedWrites"
        case .extendedProperties: return "ExtendedProperties"
        default: return ""
        }
    }
    private static let allValues: [CBCharacteristicProperties] = [.broadcast, .read, .writeWithoutResponse, .write, .notify, .indicate, .authenticatedSignedWrites, .extendedProperties]
}

extension CBPeripheral {
    var haveSerialPortCapability: Bool {
        guard let services = services else {
            return false
        }
        for service in services {
            guard service.haveSerialPortCapability else {
                continue
            }
            return true
        }
        return false
    }

    func discoverAllCharacteristics() {
        services?.forEach { discoverCharacteristics(nil, for: $0) }
    }
    var characteristics: [CBCharacteristic] {
        return services?.reduce([]) { (result, service) -> [CBCharacteristic] in
            return result + (service.characteristics ?? [])
            } ?? []
    }
}

extension CBService {
    var haveSerialPortCapability: Bool {
        return uuid.isSerialPortService
    }
    var ubloxService: UbloxService? {
        return UbloxService(rawValue: Uuid(value: uuid.data.byteArray))
    }
    public var ubloxDescription: String? {
        guard let ubloxService = ubloxService else {
            return "SERVICE"
        }
        switch ubloxService {
        case .led: return "LED"
        case .temperature: return "Temperature"
        case .battery: return "Battery"
        case .accelerometer: return "Accelerometer"
        case .gyroscope: return "Gyro"
        case .serialPort: return "Serial Port"
        case .deviceInfo: return "Device info"
        default: return "SERVICE"
        }
    }
}
extension CBCharacteristic {
    var ubloxCharacteristic: UbloxCharacteristic? {
        return UbloxCharacteristic(rawValue: Uuid(value: uuid.data.byteArray))
    }
    public var ubloxValueDescription: String? {
        let possibleCharacterisitics: [UbloxCharacteristic] = [.modelNumber,.serialNumber,.firmwareRevision,.hardwareRevision,.swRevision,.manufactName]

        guard value?.byteArray != nil, value!.count > 0,
            let characteristic = ubloxCharacteristic,
            possibleCharacterisitics.contains(characteristic) else {
                return value?.description
        }

        let unsafePointer = (value! as NSData).bytes.assumingMemoryBound(to: Int8.self)
        return String(cString: unsafePointer, encoding: .utf8)
    }

    public var ubloxDescription: String? {
        guard let ubloxCharacteristic = ubloxCharacteristic else {
            return "\(uuid)"
        }

        switch ubloxCharacteristic {
        case .serialPortFlowControlMode: return "Flow Control Mode"
        case .serialPortFifo: return "FIFO"
        case .serialPortCredits: return "Flow Control Credits"
        case .accelerometerRange: return "Range"
        case .accelerometerX: return "X Value"
        case .accelerometerY: return "Y Value"
        case .accelerometerZ: return "Z Value"
        case .gyroscopeX: return "X Value"
        case .gyroscopeY: return "Y Value"
        case .gyroscopeZ: return "Z Value"
        case .temperature: return "Temperature"
        case .ledRed: return "Red LED"
        case .ledGreen: return "Green LED"
        case .ledBlue: return "Blue LED"
        case .ledRGB: return "RGB LED"
        case .battery: return "Level"
        case .systemId: return "System Identifier"
        case .modelNumber: return "Model Number"
        case .serialNumber: return "Serial Number"
        case .firmwareRevision: return "Firmware Revision"
        case .hardwareRevision: return "Hardware Revision"
        case .swRevision: return "Software Revision"
        case .manufactName: return "Manufacturer Name"
        case .regCert: return "Regulatory Certification"
        default: return "\(uuid)"
        }
    }
}


