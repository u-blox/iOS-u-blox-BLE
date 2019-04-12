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
import CoreBluetooth

class UbloxPeripheral {
    var cbPeripheral: CBPeripheral?

    var name: String? {
        return cbPeripheral?.name
    }
    
    var services: [CBService] {
        return cbPeripheral?.services ?? []
    }

    var isSupportingSerialPort: Bool {
        return serialPortService != nil
    }
    var serialPortService: CBService? {
        return cbPeripheral?.services?.first { $0.ubloxService == .serialPort }
    }

    var state: CBPeripheralState {
        return cbPeripheral!.state
    }
    var maximumWriteValueLength: Int {
        return cbPeripheral!.maximumWriteValueLength(for: .withoutResponse)
    }
    var rssi: NSNumber?

    init(peripheral: CBPeripheral?) {
        cbPeripheral = peripheral
    }

    func write(bytes: [Byte], for ubloxCharacteristic: UbloxCharacteristic, type: CBCharacteristicWriteType = .withoutResponse) {
        guard let characteristic = cbPeripheral?.characteristics.first(where: { $0.ubloxCharacteristic == ubloxCharacteristic }) else {
            return
        }
        cbPeripheral?.writeValue(Data(bytes: bytes), for: characteristic, type: type)
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        cbPeripheral?.discoverServices(serviceUUIDs)
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService){
        cbPeripheral?.discoverCharacteristics(characteristicUUIDs, for: service)
    }
    
    func setNotify(_ enabled: Bool, for characteristic: CBCharacteristic?) {
        guard let characteristic = characteristic else {
            return
        }
        cbPeripheral?.setNotifyValue(enabled, for: characteristic)
    }
    
    func readValue(for characteristic: CBCharacteristic) {
        cbPeripheral?.readValue(for: characteristic)
    }
    
    func write(_ data: Data, for characteristic: CBCharacteristic?, type: CBCharacteristicWriteType) {
        guard let characteristic = characteristic else {
            return
        }
        cbPeripheral?.writeValue(data, for: characteristic, type: type)
    }
    
    var identifier: UUID {
        return cbPeripheral!.identifier
    }
}

func ==(lhs: UbloxPeripheral, rhs: UbloxPeripheral) -> Bool {
    return lhs.identifier == rhs.identifier
}

func ==(lhs: UbloxPeripheral, rhs: CBPeripheral) -> Bool {
    return lhs.identifier == rhs.identifier
}
