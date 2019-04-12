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

enum SerialPortState: String {
    case closed = "SP_S_CLOSED"
    case waitServiceSearch = "SP_S_WAIT_SERVICE_SEARCH"
    case waitCharacteristicSearch = "SP_S_WAIT_CHARACT_SEARCH"
    case waitInitialTxCredits = "SP_S_WAIT_INITIAL_TX_CREDITS"
    case open = "SP_S_OPEN"
    case error = "SP_S_ERROR"
}

protocol UbloxSerialPortDelegate: class {
    func serialPortDidUpdateState(_ serialPort: UbloxSerialPort)
}

class UbloxSerialPort {
    private let MAX_CREDITS: UInt8 = 32
    private let CREDITS_CLOSE: UInt8 = UInt8(bitPattern: -1)
    
    private var streamDelegate: DataStreamDelegate?
    private var pendingData: Data?
    private var txCredits: UInt8 = 0
    private var rxCredits: UInt8 = 0
    
    weak var delegate: UbloxSerialPortDelegate?

    private var peripheral: UbloxPeripheral

    var state: SerialPortState = .closed {
        didSet {
            delegate?.serialPortDidUpdateState(self)
        }
    }
    
    private var characteristics: [UbloxCharacteristic:CBCharacteristic] = [:]

    init(peripheral: UbloxPeripheral) {
        self.peripheral = peripheral
    }
    
    var withFlowControl: Bool = true

    func open() {
        guard state == .error || state == .closed else {
            return
        }
        state = .waitServiceSearch
        peripheral.discoverServices(nil)
    }

    func close() {
        if state == .open {
            peripheral.setNotify(false, for: characteristics[.serialPortFifo])
            if withFlowControl {
                peripheral.setNotify(false, for: characteristics[.serialPortCredits])
                peripheral.write(Data([CREDITS_CLOSE]), for: characteristics[.serialPortCredits], type: .withoutResponse)
            }
        }
        state = .closed
    }
    
    func processDidWriteValueFor(_ characteristic: CBCharacteristic, error: Error?) {
    }

    func processDidUpdateValueFor(_ characteristic: CBCharacteristic, error: Error?) {
        if state == .waitInitialTxCredits {
            guard characteristic.ubloxCharacteristic == .serialPortCredits, let creds = characteristic.value?.first else {
                return
            }
            txCredits += creds
            state = .open
        } else if (state == .open) {
            guard let ubloxChar = characteristic.ubloxCharacteristic, let charVal = characteristic.value else {
                return
            }
            if ubloxChar == .serialPortCredits {
                txCredits += charVal.first!
                guard let data = pendingData else {
                    return
                }
                pendingData = nil
                write(data: data)
            } else if ubloxChar == .serialPortFifo {
                streamDelegate?.onRead(data: charVal)
                guard withFlowControl else {
                    return
                }
                rxCredits -= 1
                let half = MAX_CREDITS / 2
                if rxCredits <= half {
                    rxCredits += half
                    peripheral.write(Data([half]), for: characteristics[.serialPortCredits], type: .withoutResponse)
                }
            }
        }
    }

    func processDidDiscoverCharacteristicsFor(_ service: CBService, error: Error?) {
        guard state == .waitCharacteristicSearch, service.ubloxService == .serialPort, let chars = service.characteristics else {
            return
        }
        chars.forEach {
            guard $0.ubloxCharacteristic != nil else {
                return
            }
            characteristics[$0.ubloxCharacteristic!] = $0
        }
        guard characteristics[.serialPortFifo] != nil, characteristics[.serialPortCredits] != nil else {
            state = .error
            return
        }
        if withFlowControl {
            rxCredits = MAX_CREDITS
            txCredits = 0
            peripheral.setNotify(true, for: characteristics[.serialPortCredits])
        }
        peripheral.setNotify(true, for: characteristics[.serialPortFifo])
        if withFlowControl {
            state = .waitInitialTxCredits
            peripheral.write(Data([MAX_CREDITS]), for: characteristics[.serialPortCredits], type: .withoutResponse)
        } else {
            state = .open
        }
    }

    func processDidDiscoverServices(_ error: Error?) {
        guard state == .waitServiceSearch else {
            return
        }
        for service in peripheral.services {
            guard service.ubloxService == .serialPort else {
                continue
            }
            state = .waitCharacteristicSearch
            peripheral.discoverCharacteristics(nil, for: service)
            return
        }
        state = .error
    }
    
    func processIsReadyToSend() {
        guard let data = pendingData else {
            return
        }
        pendingData = nil
        self.streamDelegate?.onWrite(data: data)
    }
}

extension UbloxSerialPort: Equatable {
    static func ==(lhs: UbloxSerialPort, rhs: UbloxSerialPort) -> Bool {
        return lhs.peripheral.identifier.uuidString == rhs.peripheral.identifier.uuidString
    }
    public static func ==(lhs: UbloxSerialPort, rhs: UbloxPeripheral) -> Bool {
        return lhs.peripheral.identifier.uuidString == rhs.identifier.uuidString
    }
}

enum TxTestMode: String {
    case onePacket = "One Packet"
    case continuous = "Continuous"

    static let allValues: [TxTestMode] = [.onePacket, .continuous]
}

extension UbloxSerialPort : DataStream {
    func setDelegate(delegate: DataStreamDelegate) {
        streamDelegate = delegate
    }
    
    func write(data: Data) {
        guard state == .open else {
            return
        }
        pendingData = data
        if !withFlowControl || txCredits > 0 {
            peripheral.write(data, for: characteristics[.serialPortFifo], type: .withoutResponse)
        }
        if withFlowControl && txCredits > 0 {
            txCredits -= 1
        }
    }
}
