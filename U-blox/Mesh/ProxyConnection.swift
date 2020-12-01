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
import nRFMeshProvision

class ProxyConnection: NSObject {
    var preferredPeripheral: CBPeripheral?
    let centralManager: CBCentralManager
    let meshNetwork: MeshNetwork
    var proxy: GattBearer?
    weak var logger: LoggerDelegate? { didSet { proxy?.logger = logger } }
    var isConnected: Bool { proxy?.isOpen ?? false }
    var name: String? { return proxy?.name }
    weak var delegate: BearerDelegate?
    weak var dataDelegate: BearerDataDelegate?
    
    init(to meshNetwork: MeshNetwork) {
        centralManager = CBCentralManager()
        self.meshNetwork = meshNetwork
        super.init()
        centralManager.delegate = self
    }
    
    func send(_ data: Data, ofType type: PduType) throws {
        guard supports(type) else { throw BearerError.pduTypeNotSupported }
        guard let proxy = proxy else { throw BearerError.bearerClosed }
        onMain {
            do {
                try proxy.send(data, ofType: type)
            }
            catch {
                NSLog("Failed to send \(data) of type \(type): \(error)")
            }
        }
    }
}

extension ProxyConnection: Bearer {
    
    public var supportedPduTypes: PduTypes { [.networkPdu, .meshBeacon, .proxyConfiguration] }
    var isOpen: Bool { proxy?.isOpen ?? false }
    
    func open() {
        if centralManager.state == .poweredOn || !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
        }
    }
    
    func close() {
        centralManager.stopScan()
        proxy?.close()
        proxy = nil
    }
}

extension ProxyConnection: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if !central.isScanning {
                central.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
            }
        case .poweredOff, .resetting:
            proxy?.close()
            proxy = nil
        default: break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard preferredPeripheral == nil || peripheral.identifier == preferredPeripheral?.identifier else { return }
        
        if let networkId = advertisementData.networkId {
            guard meshNetwork.matches(networkId: networkId) else { return }
        }
        else {
            guard let nodeIdentity = advertisementData.nodeIdentity,
                meshNetwork.matches(hash: nodeIdentity.hash, random: nodeIdentity.random) else { return }
        }
        
        central.stopScan()
        
        proxy = GattBearer(target: peripheral)
        proxy?.delegate = self
        proxy?.dataDelegate = self
        proxy?.logger = logger
        proxy?.open()
    }
}

extension ProxyConnection: GattBearerDelegate, BearerDataDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        delegate?.bearerDidOpen(bearer)
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        preferredPeripheral = nil
        proxy = nil
        delegate?.bearer(bearer, didClose: nil)
    }
    
    func bearerDidConnect(_ bearer: Bearer) {
        if !isOpen, let delegate = delegate as? GattBearerDelegate {
            delegate.bearerDidConnect(bearer)
        }
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        if !isOpen, let delegate = delegate as? GattBearerDelegate {
            delegate.bearerDidDiscoverServices(bearer)
        }
    }
    
    func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType) {
        dataDelegate?.bearer(bearer, didDeliverData: data, ofType: type)
    }
    
}
