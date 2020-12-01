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

class BluetoothDevice: NSObject, BluetoothPeripheral {
    private var characteristicsCache: [CBUUID : CBCharacteristic]
    private(set) var peripheral: CBPeripheral
    weak private var manager: BluetoothScanner?
    
    var identifier: UUID {
        return peripheral.identifier
    }
    
    private var advertisementName: String?
    var name: String? {
        return state == .connected ? peripheral.name : advertisementName
    }
    
    private(set) var rssi: Int
    
    private(set) var state: BluetoothPeripheralState
    
    var delegate: BluetoothPeripheralDelegate?
    
    init(_ peripheral: CBPeripheral, _ manager: BluetoothScanner, advertisement name: String?, _ rssi: Int) {
        self.peripheral = peripheral
        self.manager = manager
        self.advertisementName = name
        self.rssi = rssi
        characteristicsCache = [CBUUID : CBCharacteristic]()
        state = .disconnected
        super.init()
        
        self.peripheral.delegate = self
    }
    
    func connect() {
        guard state != .connected else {
            return
        }
        if let manager = manager {
            manager.connect(peripheral: self)
        } else {
            setState(.error)
        }
    }
    
    func disconnect() {
        guard state == .connected else {
            return
        }
        if let manager = manager {
            manager.disconnect(peripheral: self)
        } else {
            setState(.disconnected)
        }
    }
    
    func discover(services: [CBUUID]?) {
        if state == .connected {
            peripheral.discoverServices(services)
        }
    }
    
    func services() -> [CBUUID] {
        return peripheral.services?.map({$0.uuid}) ?? [CBUUID]()
    }
    
    func characteristics(service uuid: CBUUID?) -> [CBUUID] {
        guard let uuid = uuid else {
            return Array(characteristicsCache.keys)
        }
        guard let service = peripheral.services?.first(where: {$0.uuid == uuid}) else {
            return [CBUUID]()
        }
        return service.characteristics?.map({$0.uuid}) ?? [CBUUID]()
    }
    
    func set(characteristic: CBUUID, notify: Bool) {
        if let actualChar = characteristicsCache[characteristic] {
            peripheral.setNotifyValue(notify, for: actualChar)
        } else {
            delegate?.bluetoothPeripheral(self, set: characteristic, notify: false, ok: false)
        }
    }
    
    func write(characteristic: CBUUID, data: Data, withResponse: Bool) {
        if let actualChar = characteristicsCache[characteristic] {
            peripheral.writeValue(data, for: actualChar, type: withResponse ? .withResponse : .withoutResponse)
        } else {
            delegate?.bluetoothPeripheralReadyToWrite(self, ok: false)
        }
    }
    
    func read(characteristic: CBUUID) {
        if let actualChar = characteristicsCache[characteristic] {
            peripheral.readValue(for: actualChar)
        } else {
            delegate?.bluetoothPeripheral(self, read: characteristic, data: Data(), ok: false)
        }
    }
    
    func readRssi() {
        if state == .connected {
            peripheral.readRSSI()
        } else {
            delegate?.bluetoothPeripheralReadRssi(self, ok: false)
        }
    }
    
    func maximumDataCount(withResponse: Bool) -> Int {
        return peripheral.maximumWriteValueLength(for: withResponse ? CBCharacteristicWriteType.withResponse : .withoutResponse)
    }
    
    func updateAdvertisement(name: String?, rssi: Int) {
        advertisementName = name
        self.rssi = rssi
    }
    
    func setState(_ newState: BluetoothPeripheralState) {
        if state != newState {
            state = newState
            if state != .connected {
                characteristicsCache.removeAll()
            }
            delegate?.bluetoothPeripheralChangedState(self)
        }
    }
}

extension BluetoothDevice: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard self.peripheral == peripheral else {
            return
        }
        
        if error == nil, let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        } else {
            delegate?.bluetoothPeripheralDiscovered(self, ok: false)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.peripheral == peripheral else {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                characteristicsCache[characteristic.uuid] = characteristic
            }
        }
        delegate?.bluetoothPeripheralDiscovered(self, ok: error == nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if self.peripheral == peripheral {
            delegate?.bluetoothPeripheral(self, set: characteristic.uuid, notify: characteristic.isNotifying, ok: error == nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.peripheral == peripheral {
            delegate?.bluetoothPeripheralReadyToWrite(self, ok: error == nil)
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if self.peripheral == peripheral {
            delegate?.bluetoothPeripheralReadyToWrite(self, ok: true)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.peripheral == peripheral {
            delegate?.bluetoothPeripheral(self, read: characteristic.uuid, data: characteristic.value ?? Data(), ok: error == nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard self.peripheral == peripheral else {
            return
        }
        
        if error == nil {
            let rssi = Int(truncating: RSSI)
            self.rssi = rssi
        }
        delegate?.bluetoothPeripheralReadRssi(self, ok: error == nil)
    }
}
