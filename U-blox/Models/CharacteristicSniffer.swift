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

protocol CharacteristicHandler {
    func onCharacteristicDiscovery(_ characteristics: [CBCharacteristic])
}

class CharacteristicSniffer : CharacteristicHandler {
    private var peripheral: UbloxPeripheral
    private var notifications: [UbloxCharacteristic]
    private var reads: [UbloxCharacteristic]
    
    init(for peripheral: UbloxPeripheral, readAndNotify notifications: [UbloxCharacteristic], onlyRead reads: [UbloxCharacteristic]) {
        self.peripheral = peripheral
        self.notifications = notifications
        self.reads = reads
    }
    
    func onCharacteristicDiscovery(_ characteristics: [CBCharacteristic]) {
        for char in characteristics {
            guard let ubloxChar = char.ubloxCharacteristic else {
                continue
            }
            let isNotify = notifications.contains(ubloxChar)
            let isRead = reads.contains(ubloxChar) || isNotify
            if isNotify {
                peripheral.setNotify(true, for: char)
            }
            if isRead {
                peripheral.readValue(for: char)
            }
        }
    }
}
