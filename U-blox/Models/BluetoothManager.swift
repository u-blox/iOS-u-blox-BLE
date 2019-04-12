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

class BluetoothManager: NSObject {

    static let shared = BluetoothManager()
    
    fileprivate(set) var currentPeripheral: UbloxPeripheral?
    fileprivate(set) var currentSerialPort: UbloxSerialPort?
    var currentCharacteristicsHandler: CharacteristicHandler?
    fileprivate var centralManager = CBCentralManager()

    fileprivate var serialPortReconnection = false
    fileprivate var serialPortReconnectionCompletionHandler: (() -> Void)?
    fileprivate var peripheralConnected: (() -> Void)?

    var peripherals: [UbloxPeripheral] = []
    var isScanningForPeripherals: Bool = false {
        didSet {
            if isScanningForPeripherals {
                Logger.quiet(message: "Bluetooth Manager start scan for peripherals")
                centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:1])
            } else {
                Logger.quiet(message: "Bluetooth Manager stop scan for peripherals")
                centralManager.stopScan()
            }
        }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        Logger.quiet(message: "Bluetooth Manager initialized")
    }
    func setupSerialPort(completionHandler: (() -> Void)? = nil) {
        serialPortReconnection = true
        self.serialPortReconnectionCompletionHandler = completionHandler
        disconnect(currentPeripheral!)
    }
}

extension BluetoothManager {
    func connect(_ peripheral: UbloxPeripheral, completionHandler: (() -> Void)? = nil) {
        peripheralConnected = completionHandler
        guard peripheral.state == .disconnected else {
            return
        }
        Logger.quiet(message: "Bluetooth Manager start connect peripheral: \(peripheral.name ?? "No name")")
        centralManager.connect(peripheral.cbPeripheral!, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey:1])
    }
    func disconnect(_ peripheral: UbloxPeripheral) {
        guard peripheral.state == .connected || peripheral.state == .connecting else {
            return
        }
        Logger.quiet(message: "Bluetooth Manager start cancel connection to peripheral: \(peripheral.name ?? "No name")")
        centralManager.cancelPeripheralConnection(peripheral.cbPeripheral!)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Logger.quiet(message: "Bluetooth Manager connected to peripheral: \(peripheral.name ?? "No name")")
        peripheral.discoverServices(nil)
        peripheral.readRSSI()

        currentPeripheral = peripherals.first { $0 == peripheral }

        if serialPortReconnection {
            currentSerialPort = UbloxSerialPort(peripheral: UbloxPeripheral(peripheral: peripheral))
            serialPortReconnectionCompletionHandler?()
            serialPortReconnection = false
            serialPortReconnectionCompletionHandler = nil
        } else {
            peripheralConnected?()
            peripheralConnected = nil
        }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Logger.quiet(message: "Bluetooth Manager disconnected from peripheral: \(peripheral.name ?? "No name")")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        if serialPortReconnection, let ubloxPeripheral = peripherals.first(where: { $0 == peripheral}) {
            connect(ubloxPeripheral)
        } else {
            NotificationCenter.default.post(notificationType: .peripheralDisconnected, object: self, userInfo: [
                UbloxDictionaryKeys.name : currentPeripheral?.name ?? "Peripheral"
                ])
        }
        currentPeripheral = nil
        currentSerialPort = nil
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Logger.verbose(message: "Bluetooth Manager discovered peripheral: \(peripheral.name ?? "No name")")

        let index = peripherals.index { $0 == peripheral }
        var notificationType: UbloxNotificationTypes

        if let index = index {
            let ubloxPeripheral = UbloxPeripheral(peripheral: peripheral)
            ubloxPeripheral.rssi = RSSI
            peripherals.remove(at: index)
            peripherals.insert(ubloxPeripheral, at: index)
            notificationType = .peripheralUpdated
        } else {
            peripheral.delegate = self
            let ubloxPeripheral = UbloxPeripheral(peripheral: peripheral)
            ubloxPeripheral.rssi = RSSI
            peripherals.append(ubloxPeripheral)
            notificationType = .peripheralListChanged
        }

        NotificationCenter.default.post(notificationType: notificationType, object: self, userInfo: [:])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Logger.quiet(message: "Bluetooth Manager failed to connect peripheral: \(peripheral.name ?? "No name")")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        NotificationCenter.default.post(notificationType: .peripheralConnectionFailed, object: self, userInfo: [
            UbloxDictionaryKeys.name : peripheral.name ?? "Peripheral"
            ])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: Logger.quiet(message: "CoreBluetooth BLE hardware is Powered On")
        case .poweredOff: Logger.quiet(message: "CoreBluetooth BLE hardware is Powered Off")
        case .unauthorized: Logger.quiet(message: "CoreBluetooth BLE hardware is Unauthorized")
        case .unsupported: Logger.quiet(message: "CoreBluetooth BLE hardware is Unsupported")
        case .resetting: Logger.quiet(message: "CoreBluetooth BLE hardware is Resetting")
        case .unknown: Logger.quiet(message: "CoreBluetooth BLE hardware is Unknown")
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        Logger.quiet(message: "Bluetooth Manager discovered services for peripheral: \(peripheral.name ?? "No name")")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        peripheral.discoverAllCharacteristics()

        guard peripheral.haveSerialPortCapability else {
            return
        }

        defer {
            NotificationCenter.default.post(notificationType: .serviceDiscovered, object: self, userInfo: [
                UbloxDictionaryKeys.ubloxPeripheral : peripherals.first { $0 == peripheral}!
                ])
        }

        currentSerialPort?.processDidDiscoverServices(error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Logger.quiet(message: "Bluetooth Manager discovered characteristics for peripheral: \(peripheral.name ?? "No name") on serice: \(service.uuid.uuidString)")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        guard let characteristics = service.characteristics else {
            return
        }
        currentCharacteristicsHandler?.onCharacteristicDiscovery(characteristics)
        guard service.haveSerialPortCapability else {
            return
        }
        currentSerialPort?.processDidDiscoverCharacteristicsFor(service, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Logger.quiet(message: "Bluetooth Manager wrote value for peripheral: \(peripheral.name ?? "No name") on characteristic: \(characteristic.uuid.uuidString)")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        currentSerialPort?.processDidWriteValueFor(characteristic, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Logger.quiet(message: "Bluetooth Manager updated value for peripheral: \(peripheral.name ?? "No name") on characteristic: \(characteristic.uuid.uuidString)")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        currentSerialPort?.processDidUpdateValueFor(characteristic, error: error)

        guard error == nil else {
            return
        }

        guard let ubloxCharacteristic = characteristic.ubloxCharacteristic else {
            return
        }

        NotificationCenter.default.post(notificationType: .characteristicValueUpdated, object: self, userInfo: [
            UbloxDictionaryKeys.ubloxCharacteristic : ubloxCharacteristic,
            UbloxDictionaryKeys.characteristic : characteristic,
            UbloxDictionaryKeys.ubloxPeripheral : currentPeripheral!
            ])
    }
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Logger.verbose(message: "Bluetooth Manager read RSSI for peripheral: \(peripheral.name ?? "No name")")
        if let error = error {
            Logger.quiet(message: "Bluetooth Manager error: \(error.localizedDescription) occured for peripheral: \(peripheral.name ?? "No name")")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
            peripheral.readRSSI()
        }
        NotificationCenter.default.post(notificationType: .rssiUpdated, object: self, userInfo: [
            UbloxDictionaryKeys.uuid : peripheral.identifier.uuidString,
            UbloxDictionaryKeys.rssi : RSSI
            ])
    }
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        currentSerialPort?.processIsReadyToSend()
    }
}

