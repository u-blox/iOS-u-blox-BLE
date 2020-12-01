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

class BluetoothScanner: NSObject, BluetoothCentral {
    private var manager: CBCentralManager!
    private var devicesCache: [BluetoothDevice]
    
    private(set) var state: BluetoothCentralState
    
    weak var delegate: BluetoothCentralDelegate?
    
    var foundDevices: [BluetoothPeripheral] {
        return Array(devicesCache)
    }
    
    override init() {
        state = .off
        devicesCache = [BluetoothDevice]()
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan(withServices: [CBUUID]?) {
        guard state == .on else {
            return
        }
        manager.scanForPeripherals(withServices: withServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey:1])
        updateState()
    }
    
    func stop() {
        guard state == .scanning else {
            return
        }
        manager.stopScan()
        updateState()
    }
    
    func connect(peripheral: BluetoothDevice) {
        guard state != .off else {
            return
        }
        manager.connect(peripheral.peripheral, options: nil)
    }
    
    func disconnect(peripheral: BluetoothDevice) {
        guard state != .off else {
            return
        }
        manager.cancelPeripheralConnection(peripheral.peripheral)
    }
    
    private func updateState() {
        let newState: BluetoothCentralState = manager.state == .poweredOn ? manager.isScanning ? .scanning : .on : .off
        if (newState == .off) {
            for device in devicesCache {
                device.setState(.disconnected)
            }
            devicesCache.removeAll()
        }
        if newState != state {
            state = newState
            delegate?.bluetoothCentralChangedState(self)
        }
    }
    
    private func deviceWith(_ peripheral: CBPeripheral) -> BluetoothDevice? {
        return devicesCache.first(where: {$0.peripheral == peripheral})
    }
}

extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if manager == central {
            updateState()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard manager == central else {
            return
        }
        
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let rssi = Int(truncating: RSSI)
        
        if let device = deviceWith(peripheral) {
            device.updateAdvertisement(name: name, rssi: rssi)
            delegate?.bluetoothCentral(self, found: device)
        } else {
            let device = BluetoothDevice(peripheral, self, advertisement: name, rssi)
            devicesCache.append(device)
            delegate?.bluetoothCentral(self, found: device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if manager == central {
            deviceWith(peripheral)?.setState(.connected)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if manager == central {
            deviceWith(peripheral)?.setState(error == nil ? .disconnected : .error)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if manager == central {
            deviceWith(peripheral)?.setState(.error)
        }
    }
}
