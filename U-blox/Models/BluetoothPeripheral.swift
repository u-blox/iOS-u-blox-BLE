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

protocol BluetoothPeripheral {
    var identifier: UUID {get}
    var name: String? {get}
    var rssi: Int {get}
    var state: BluetoothPeripheralState {get}
    
    var delegate: BluetoothPeripheralDelegate? {get set}
    
    func connect()
    func disconnect()
    
    func discover(services: [CBUUID]?)
    func services() -> [CBUUID]
    func characteristics(service: CBUUID?) -> [CBUUID]
    
    func set(characteristic: CBUUID, notify: Bool)
    func write(characteristic: CBUUID, data: Data, withResponse: Bool)
    func read(characteristic: CBUUID)
    
    func readRssi()
    func maximumDataCount(withResponse: Bool) -> Int
}

enum BluetoothPeripheralState {case disconnected, connected, error}

protocol BluetoothPeripheralDelegate: class {
    func bluetoothPeripheralChangedState(_ peripheral: BluetoothPeripheral)
    func bluetoothPeripheralDiscovered(_ peripheral: BluetoothPeripheral, ok: Bool)
    
    func bluetoothPeripheral(_ peripheral: BluetoothPeripheral, set characteristic: CBUUID, notify: Bool, ok: Bool)
    func bluetoothPeripheralReadyToWrite(_ peripheral: BluetoothPeripheral, ok: Bool)
    func bluetoothPeripheral(_ peripheral: BluetoothPeripheral, read characteristic: CBUUID, data: Data, ok: Bool)
    
    func bluetoothPeripheralReadRssi(_ peripheral: BluetoothPeripheral, ok: Bool)
}
