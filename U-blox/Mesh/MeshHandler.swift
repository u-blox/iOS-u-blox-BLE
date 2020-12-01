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
import nRFMeshProvision
import os.log
import CoreBluetooth

/// The main class coordinating all mesh activities.
class MeshHandler {
    
    let peripheral: UbloxPeripheral
    let settings: MeshSettings
    
    private(set) var networkManager: MeshNetworkManager!
    private var connection: ProxyConnection!
    private var nodes = [UbloxNode]()
    
    // Computed properties.
    var network: MeshNetwork { networkManager.meshNetwork! }
    var proxyName: String? { connection.proxy?.name }
    private var applicationKey: ApplicationKey { network.applicationKeys.first! }
    private var networkKey: NetworkKey { network.networkKeys.first! }
    private var configModel: Model { networkManager.localElements.first!.models[1] }
    
    init(peripheral: UbloxPeripheral, settings: MeshSettings) {
        
        self.peripheral = peripheral
        self.settings = settings
        
        networkManager = MeshNetworkManager()
        networkManager.delegate = self
        networkManager.logger = self
        networkManager.acknowledgmentMessageInterval = 60 // Dont' let nrf handle resends!
        
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        _ = networkManager.createNewMeshNetwork(withName: settings.name, by: provisioner)
        
        if let netKey = Data(hex: settings.netKeyString), let appKey = Data(hex: settings.appKeyString) {
            do {
                _ = try network.remove(networkKeyAt: 0, force: true)
                _ = try network.add(networkKey: netKey, name: "Network key")
                _ = try network.add(applicationKey: appKey, name: "Application key")
            } catch { print(error) }
        }
            
        let sensorModel = settings.makeSensorModel()
        let onOffModel = Model(sigModelId: 0x1001, delegate: GenericOnOffClientDelegate())
        let lightModel = Model(sigModelId: 0x1309, delegate: LightHSLServerClientDelegate())
        let element0 = Element(name: "Primary Element", location: .first, models: [
            onOffModel,
            sensorModel,
            lightModel,
        ])
        
        networkManager.localElements = [element0]
        
        // Bind application key to onOffModel.
        configModel.delegate?.model(configModel,
                                    didReceiveResponse: ConfigSIGModelAppList(responseTo: ConfigSIGModelAppGet(of: onOffModel)!, with: [applicationKey]),
                                    toAcknowledgedMessage: ConfigSIGModelAppGet(of: onOffModel)!,
                                    from: onOffModel.parentElement!.unicastAddress)
        
        // Bind application key to lightModel.
        configModel.delegate?.model(configModel,
                                    didReceiveResponse: ConfigSIGModelAppList(responseTo: ConfigSIGModelAppGet(of: lightModel)!, with: [applicationKey]),
                                    toAcknowledgedMessage: ConfigSIGModelAppGet(of: lightModel)!,
                                    from: lightModel.parentElement!.unicastAddress)
        
        // Subscribe to sensor output.
        do {
            let group = try! Group(name: "group", address: settings.subscribedGroup)
            try! network.add(group: group)
            configModel.delegate?.model(configModel,
                                        didReceiveResponse: ConfigModelSubscriptionStatus(confirmAdding: group, to: sensorModel)!,
                                        toAcknowledgedMessage: ConfigModelSubscriptionAdd(group: group, to: sensorModel)!,
                                        from: 0x0001)
            
            // Bind application key to sensor model.
            if settings.isVendorModel {
                configModel.delegate?.model(configModel,
                                            didReceiveResponse: ConfigVendorModelAppList(responseTo: ConfigVendorModelAppGet(of: sensorModel)!, with: [applicationKey]),
                                            toAcknowledgedMessage: ConfigVendorModelAppGet(of: sensorModel)!, from: sensorModel.parentElement!.unicastAddress)
            }
            else {
                configModel.delegate?.model(configModel,
                                            didReceiveResponse: ConfigSIGModelAppList(responseTo: ConfigSIGModelAppGet(of: sensorModel)!, with: [applicationKey]),
                                            toAcknowledgedMessage: ConfigSIGModelAppGet(of: sensorModel)!, from: sensorModel.parentElement!.unicastAddress)
            }
        }
        
        // The ProxyConnection manages the link to the proxy node.
        connection = ProxyConnection(to: network)
        connection.dataDelegate = networkManager
        connection.delegate = self
        connection.logger = self
        connection.preferredPeripheral = peripheral.cbPeripheral
        networkManager.transmitter = connection
        
        NSLog("Local address: \(network.nodes.first!.unicastAddress)")
    }
}

private extension MeshHandler {
    func addNode(forAddress address: Address) -> UbloxNode? {
        let useName = settings.makeNodeName(address)
        guard let deviceKey = Data(hex: settings.devKeyString) else { return nil }
        guard let node = Node(lowSecurityNode: useName,
                           with: 1, // TODO
                           elementsDeviceKey: deviceKey,
                           andAssignedNetworkKey: networkKey,
                           andAddress: address) else { return nil }
        do { try network.add(node: node) } catch { NSLog("Failed to add node for address 0x%X", address) }
    
        // This line adds the sensor models to the nrf node. Otherwise sending config messages through nRF won't work.
        configModel.delegate?.model(configModel,
                                    didReceiveResponse: ConfigCompositionDataStatus.dummyCompositionStatus!,
                                    toAcknowledgedMessage: ConfigCompositionDataGet(),
                                    from: node.unicastAddress)
        
        let uNode = UbloxNode(node: node, networkId: networkKey.networkId.hex, delegate: networkManager)
        nodes.append(uNode)
        return uNode
    }
    
    func node(forAddress address: Address, missing: inout Bool) -> UbloxNode {
        let baseAddress = settings.makeBaseAddress(address)
        var uNode = nodes.first { $0.node.unicastAddress == baseAddress }
        missing = uNode == nil
        if missing {
            uNode = addNode(forAddress: baseAddress)
        }
        return uNode!
    }
}

extension MeshHandler: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        onMain {
            NSLog("Received \(message) from 0x%X to 0x%X", source, destination)
            var newNode = false
            let uNode = self.node(forAddress: source, missing: &newNode)
            uNode.receivedFromNode(message: message)
            
            // Report added node. Using notifications since several view controllers may be interested.
            if newNode {
                notifications.post(notificationType: .meshNodeAdded, object: self, userInfo: [Notification.kNotificationNodeKey: uNode])
                
                // Report proxy connection as complete when first status message received.
                if self.nodes.count == 1 {
                    notifications.post(notificationType: .meshConnectionProgress, object: self, userInfo: [Notification.kProgressKey: Float(1)])
                }
            }
        }
    }
}

extension MeshHandler: BearerDelegate {
    func bearerDidOpen(_ bearer: Bearer) { }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        notifications.post(notificationType: .meshConnectionLost, object: self)
    }
}

extension MeshHandler: LoggerDelegate {
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: category.rawValue)
        if level == .error {
            os_log("%{public}@", log: log, type: level.type, message)
        }
        
        // Using log messages to indicate connection progress to avoid patching nRF.
        let states = ["Connecting to",
                      "Discovering serv",
                      "Discovering char",
                      "Enabling notifications",
                      "Secure Network Beacon",
                      "FilterStatus"]
        if let index = states.firstIndex(where: { message.contains($0) }) {
            let progress = Float(index + 1) / Float(states.count + 1)
            notifications.post(notificationType: .meshConnectionProgress, object: self, userInfo: [Notification.kProgressKey: Float(progress)])
        }
    }
}

private extension LogLevel {
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
}

let kNetKeyKey = "kNetKeyKey"
let kAppKeyKey = "kAppKeyKey"

struct MeshSettings {
    private static let kOverviewTypesBaseKey = "kOverviewTypesKey"
    private static let kDetailTypesBaseKey = "kDetailTypesKey"
    
    var netKeyString: String
    var appKeyString: String
    var devKeyString: String
    var name: String
    var subscribedGroup: Address
    var makeBaseAddress: (_ address: Address) -> Address
    var makeNodeName: (_ address: Address) -> String?
    var isVendorModel: Bool
    var makeSensorModel: () -> Model
    var getDetailCellTypes: [BaseCell.Type] { cellTypes(forKey: Self.kDetailTypesBaseKey, defaultTypes: detailCellTypes) }
    var getOverviewCellTypes: [BaseCell.Type] { cellTypes(forKey: Self.kOverviewTypesBaseKey, defaultTypes: overviewCellTypes) }
    func setDetailCellTypes(_ types: [BaseCell.Type]) { setCellTypes(types, forKey: Self.kDetailTypesBaseKey) }
    func setOverViewCellTypes(_ types: [BaseCell.Type]) { setCellTypes(types, forKey: Self.kOverviewTypesBaseKey) }
    
    private var overviewCellTypes: [BaseCell.Type] { [NameCell.self, ComboGraphCell.self] }
    
    private var detailCellTypes: [BaseCell.Type] {
        
        // Types common for c209 and office network.
        var types = [
            EditableNameCell.self,
            AddressCell.self,
            
            TemperatureGraphCell.self,
            HumidityGraphCell.self,
            PressureGraphCell.self,
            AmbientLightGraphCell.self,
        ]
        
        // Additional types for c209.
        if self.networkId == Self.basedOn(.c209).networkId {
            types.append(contentsOf: [LightSwitchCell.self,
                                      HSLButtonCell.self,
                                      HSLSliderCell.self,
                                      LEDGraphCell.self,
                                      
                                      Orientation3DCell.self,
                                      OrientationGraphCell.self,
                                      
                                      RelayCell.self,
                                      CadenceCell.self])
        }
        
        return types
    }
    
    var networkId: Data { OpenSSLHelper().calculateK3(withN: Data(hex: netKeyString)) }
    
    private func cellTypeKey(_ key: String) -> String { key + "-" + netKeyString.prefix(4) }
    
    private func cellTypes(forKey key: String, defaultTypes: [BaseCell.Type]) -> [BaseCell.Type] {
        guard let typeNames = defaults.object(forKey: cellTypeKey(key)) as? [String] else { return defaultTypes }
        guard let types = typeNames.map({ NSClassFromString($0) }) as? [BaseCell.Type] else { return defaultTypes }
        return types
    }
    
    private func setCellTypes(_ types: [BaseCell.Type], forKey key: String) {
        let typeNames = types.map({ NSStringFromClass($0) })
        defaults.set(typeNames, forKey: cellTypeKey(key))
    }
    
    enum Predefined: Int {
        case c209 = 0
        case office = 1
    }
    
    private static let kSettingsKey = "kSettingsKey"
    static var current: Predefined {
        get { Predefined(rawValue: defaults.integer(forKey: kSettingsKey)) ?? .c209 }
        set { defaults.set(newValue.rawValue, forKey: kSettingsKey) }
    }
    
    static func basedOn(_ predefinedType: Predefined) -> MeshSettings {
       
        var settings = predefinedType == .office ?
            MeshSettings(netKeyString: "5F5F6E6F726469635F5F73656D695F5F",
                         appKeyString: "5F116E6F726469635F5F73656D695F5F",
                         devKeyString: "00000000000000000000000000000000",
                         name: "Office mesh",
                         subscribedGroup: 0xC001,
                         makeBaseAddress: { address in address | 0x1}, // TODO
                makeNodeName: { address in "Node \((address - 0x100) / 2)" },
                isVendorModel: true,
                makeSensorModel: { Model(vendorModelId: 0x3, companyId: 0x0059, delegate: SimpleSensorClientDelegate()) }
            )
            :
            MeshSettings(netKeyString: "5F5F6E6F726469635F5F73656D695F50", // "B945C23142438E0FD3D4A54A3E53D6E4",
                         appKeyString: "5F116E6F726469635F5F73656D695F5F", // "A335BA0CA7DC4170AD13CBFF85223601",
                         devKeyString: "5F116E6F726469635F5F73656D695F51",
                         name: "C209 mesh",
                         subscribedGroup: 0xC111,
                         makeBaseAddress: { $0 },
                         makeNodeName: { address in "C209 node \(address.hex)" },
                         isVendorModel: false,
                         makeSensorModel: { Model(sigModelId: 0x1100, delegate: SensorServerClientDelegate()) }
        )
        
        let currentAppKeyString = defaults.string(forKey: kAppKeyKey) ?? settings.appKeyString
        let currentNetKeyString = defaults.string(forKey: kNetKeyKey) ?? settings.netKeyString
        settings.netKeyString = currentNetKeyString
        settings.appKeyString = currentAppKeyString
                
        // Uncomment to clean up deprecated cell configurations for a device.
        // defaults.removeObject(forKey: settings.cellTypeKey(kDetailTypesBaseKey))
        // defaults.removeObject(forKey: settings.cellTypeKey(kOverviewTypesBaseKey))
        
        return settings
    }
}

class StatusEntry: Codable, CustomStringConvertible {
    var timeStamp: CFAbsoluteTime
    var status: SensorStatus
    
    init(status: SensorStatus, timeStamp: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) {
        self.timeStamp = timeStamp
        self.status = status
    }
    
    var description: String {
        let date = Date(timeIntervalSinceReferenceDate: timeStamp)
        let formatter = DateFormatter()
        formatter.dateFormat = .none
        formatter.timeStyle = .long
        return "[" + formatter.string(from: date) + "] " + status.description
    }
    
    enum CodingKeys: String, CodingKey {
        case message, status = "s"
        case timeStamp = "t"
    }
    
    enum EntryError: Error {
        case decodingFailed
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        timeStamp = try container.decode(CFTimeInterval.self, forKey: .timeStamp)
        
        var tmpStatus: SensorStatus?
        if tmpStatus == nil { do { tmpStatus = try container.decode(SimpleSensorStatus.self, forKey: .status) } catch { } }
        if tmpStatus == nil { do { tmpStatus = try container.decode(SensorServerStatus.self, forKey: .status) } catch { } }
        if tmpStatus == nil { do { tmpStatus = try container.decode(UbloxLightHSLStatus.self, forKey: .status) } catch { } }
        
        guard tmpStatus != nil else { throw EntryError.decodingFailed }
        status = tmpStatus!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeStamp, forKey: .timeStamp)
        try container.encode(status, forKey: .status)
    }

}

extension Array where Element: StatusEntry {
    func lastStatus(for type: SensorType) -> SensorStatus? {
        last { type.sensorValue(for: $0.status) != nil }?.status
    }
    
    func lastValue(for type: SensorType) -> CGFloat? {
        if let foundLast = lastStatus(for: type) {
            return type.sensorValue(for: foundLast)
        }
        return nil
    }
}

extension Notification {
    fileprivate static let kNotificationNodeKey = "kNotificationNodeKey"
    var meshNode: UbloxNode? { self.userInfo?[Notification.kNotificationNodeKey] as? UbloxNode }
    
    fileprivate static let kProgressKey = "kProgressKey"
    var progress: Float? { self.userInfo?[Notification.kProgressKey] as? Float }
}

private extension ConfigCompositionDataStatus {
    static var dummyCompositionStatus: ConfigCompositionDataStatus? {
        var data = Data()
        data.append(0) // page
        data.append(contentsOf: [1, 2]) // company
        data.append(contentsOf: [3, 4]) // product
        data.append(contentsOf: [5, 6]) // version
        data.append(contentsOf: [0, 0]) // minimumNumberOfReplayProtectionList
        data.append(contentsOf: [0x3, 0]) // features
        
        var elementData = Data()
        var loc = Location.fifth.rawValue
        elementData.append(UnsafeBufferPointer(start: &loc, count: 1)) // location
        elementData.append(1) // num sig models
        elementData.append(1) // num vendor models)
        var sigModel = 0x1100 as UInt16
        elementData.append(UnsafeBufferPointer(start: &sigModel, count: 1)) // on off server
        var companyId = 0x0059 as UInt16
        var vendorModel = 0x0002 as UInt16
        elementData.append(UnsafeBufferPointer(start: &companyId, count: 1)) // nordic sc
        elementData.append(UnsafeBufferPointer(start: &vendorModel, count: 1)) // simple sensor
        
        data.append(elementData)
        return ConfigCompositionDataStatus(parameters: data)
    }
}
