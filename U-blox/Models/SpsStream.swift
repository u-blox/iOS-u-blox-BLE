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

class SpsStream: DataStream {
    static let serialPortService = CBUUID(data: Data([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01]))
    static let fifoCharacteristic = CBUUID(data: Data([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x03]))
    static let creditsCharacteristic = CBUUID(data: Data([0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83, 0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x04]))
    static let maxCredits: UInt8 = 32
    static let closingCredits: UInt8 = 255
    
    private var peripheral: BluetoothPeripheral
    private var flowControl: Bool
    private var txCredits: UInt8
    private var rxCredits: UInt8
    private var pendingData: Data?
    
    private(set) var streamState: DataStreamState
    weak var delegate: DataStreamDelegate?
    
    init(_ peripheral: BluetoothPeripheral) {
        streamState = .closed
        flowControl = true
        txCredits = 0
        rxCredits = 0
        self.peripheral = peripheral
        self.peripheral.delegate = self
    }
    
    func setDelegate(delegate: DataStreamDelegate) {
        self.delegate = delegate
    }
    
    func open() {
        open(withFlowControl: true)
    }
    
    func open(withFlowControl: Bool) {
        if streamState != .opened {
            txCredits = 0
            rxCredits = 0
            flowControl = withFlowControl
            peripheral.connect()
        }
    }
    
    func close() {
        if streamState == .opened {
            peripheral.disconnect()
        }
    }
    
    func write(data: Data) {
        pendingData = data
        if !flowControl || txCredits > 0 {
            peripheral.write(characteristic: SpsStream.fifoCharacteristic, data: data, withResponse: false)
        }
        if flowControl && txCredits > 0 {
            txCredits -= 1
        }
    }
    
    private func closeWithError() {
        streamState = .error
        peripheral.disconnect()
    }
    
    private func setState(_ newState: DataStreamState) {
        guard newState != streamState else {
            return
        }
        if streamState != .error || newState != .closed {
            streamState = newState
        }
        delegate?.dataStreamChangedState(self)
    }
}

extension SpsStream: BluetoothPeripheralDelegate {
    func bluetoothPeripheralChangedState(_ peripheral: BluetoothPeripheral) {
        guard self.peripheral.identifier == peripheral.identifier else {
            return
        }
        
        switch peripheral.state {
        case .connected:
            peripheral.discover(services: [SpsStream.serialPortService])
        case .disconnected:
            setState(.closed)
        case .error:
            setState(.error)
        }
    }
    
    func bluetoothPeripheralDiscovered(_ peripheral: BluetoothPeripheral, ok: Bool) {
        guard streamState != .opened && self.peripheral.identifier == peripheral.identifier else {
            return
        }
        
        let sps = peripheral.characteristics(service: SpsStream.serialPortService)
        if sps.contains(SpsStream.fifoCharacteristic) && sps.contains(SpsStream.creditsCharacteristic) {
            peripheral.set(characteristic: flowControl ? SpsStream.creditsCharacteristic : SpsStream.fifoCharacteristic, notify: true)
        } else {
            closeWithError()
        }
    }
    
    func bluetoothPeripheral(_ peripheral: BluetoothPeripheral, set characteristic: CBUUID, notify: Bool, ok: Bool) {
        guard self.peripheral.identifier == peripheral.identifier else {
            return
        }
        
        guard ok && notify else {
            return closeWithError()
        }
        
        if characteristic == SpsStream.creditsCharacteristic {
            peripheral.set(characteristic: SpsStream.fifoCharacteristic, notify: true)
        }
        
        if characteristic == SpsStream.fifoCharacteristic {
            if flowControl {
                rxCredits = SpsStream.maxCredits
                txCredits = 0
                peripheral.write(characteristic: SpsStream.creditsCharacteristic, data: Data([SpsStream.maxCredits]), withResponse: false)
            } else {
                setState(.opened)
            }
        }
    }
    
    func bluetoothPeripheralReadyToWrite(_ peripheral: BluetoothPeripheral, ok: Bool) {
        if let data = pendingData {
            pendingData = nil
            delegate?.dataStream(self, wrote: ok ? data : Data())
        }
    }
    
    func bluetoothPeripheral(_ peripheral: BluetoothPeripheral, read characteristic: CBUUID, data: Data, ok: Bool) {
        guard self.peripheral.identifier == peripheral.identifier else {
            return
        }
        
        if characteristic == SpsStream.creditsCharacteristic && ok {
            guard data[0] != SpsStream.closingCredits else {
                return peripheral.disconnect()
            }
            txCredits += data[0]
            setState(.opened)
            if let data = pendingData {
                write(data: data)
            }
        }
        
        if characteristic == SpsStream.fifoCharacteristic {
            delegate?.dataStream(self, read: data)
            guard flowControl else {
                return
            }
            rxCredits -= 1
            let half = SpsStream.maxCredits / 2
            if rxCredits <= half {
                rxCredits += half
                peripheral.write(characteristic: SpsStream.creditsCharacteristic, data: Data([half]), withResponse: false)
            }
        }
    }
    
    func bluetoothPeripheralReadRssi(_ peripheral: BluetoothPeripheral, ok: Bool) {}
}
