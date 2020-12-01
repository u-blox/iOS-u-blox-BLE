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

import nRFMeshProvision

class UbloxNode {
    
    let node: Node
    let networkId: String
    private weak var delegate: MeshNetworkManager?
    var statusEntries = [StatusEntry]()
    private var readingCountSinceSync = 0
    
    private var applicationKey: ApplicationKey? { delegate?.meshNetwork?.applicationKeys.first }
    private var nodeKey: String { networkId + "-" + node.unicastAddress.hex }
    private var entriesKey: String { nodeKey + "-" + "entries" }
    private var nameKey: String { nodeKey + "-" + "name"}
    var name: String {
        get { defaults.string(forKey: nameKey) ?? node.name ?? node.unicastAddress.hex }
        set { defaults.set(newValue, forKey: nameKey) }
    }
    func removeName() { defaults.removeObject(forKey: nameKey) }
        
    init(node: Node?, networkId: String, delegate: MeshNetworkManager) {
        self.node = node ?? Node(lowSecurityNode: "Dummy", with: 1, elementsDeviceKey: Data(), andAssignedNetworkKey: (delegate.meshNetwork?.networkKeys.first)!, andAddress: Address(0xA))!
        self.networkId = networkId
        self.delegate = delegate
        readEntries()
        
        // Make sure sensor data is saved.
        notifications.addObserver(self, selector: #selector(saveData), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notifications.addObserver(self, selector: #selector(saveData), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit { saveData() }

    // General setting request handling.
    
    private var requestingCells = Set<DynamicCell>()
    func removeRequestCell(_ cell: DynamicCell) { assert(requestingCells.contains(cell)); requestingCells.remove(cell) }
    func addRequestCell(_ cell: DynamicCell) { assert(!requestingCells.contains(cell)); requestingCells.insert(cell) }
    
    func requestCompleted(for statusType: MeshMessage.Type) {
        let matchingCells = requestingCells.filter { $0.requestStatusTypes?.contains { $0 == statusType } ?? false }
        matchingCells.forEach { $0.handleStatus(requestNode: self) }
    }
    
    func pollSensor(type: SensorServerStatus.PropertyID) {
        sendToNode(SensorServerGet(type: type))
    }
    
    struct ValueState: OptionSet {
        let rawValue: UInt8
        static let hasValue = ValueState(rawValue: 1 << 0)
        static let getsValue = ValueState(rawValue: 1 << 1)
        static let hasAndGetsValue: ValueState = [.hasValue, .getsValue]
    }
    
    private func state(of status: Any?, type: ResponseMessage.Type) -> ValueState {
        var state: ValueState = []
        if status != nil { state.insert(.hasValue) }
        if status == nil || activeMessages.contains(opCodes: type.matchingRequestOpCodes) {
            state.insert(.getsValue)
        }
        return state
    }
    
    // Relay setting handling.
    
    private(set) var relayOn: Bool?
    
    var relayState: ValueState { state(of: relayOn, type: ConfigRelayStatus.self) }
    func getRelayOn() -> ValueState {
        if relayState == .getsValue { sendToNode(ConfigRelayGet()) }
        else { requestCompleted(for: ConfigRelayStatus.self) }
        return relayState
    }
    
    func setRelay(on: Bool) {
        sendToNode(on ?
            ConfigRelaySet(count: 7, steps: 31):
            ConfigRelaySet())
    }
    
    // Light setting handling.
    
    private(set) var lightHSL: HSV<CGFloat>?
    var hslState: ValueState { state(of: lightHSL, type: UbloxLightHSLStatus.self) }
    
    var lightSwitchOn: Bool? { lightHSL?.brightness ?? 0 > 0 }
    
    func getLightOn() -> ValueState { getLightHSL() }
    
    func setLight(on: Bool) {
        let hsl = (on ? UIColor.white: .black).hsv
        setLightHSL(hsl: hsl)
    }
    
    func getLightHSL() -> ValueState {
        if hslState == .getsValue { sendToNode(UbloxLightHSLGet()) }
        else { requestCompleted(for: UbloxLightHSLStatus.self) }
        return hslState
    }
    
    func setLightHSL(hsl: HSV<CGFloat>) {
        sendToNode(UbloxLightHSLSet(hsl))
    }
    
    // Publication setting handling.
    
    private var publicationStatus: ConfigModelPublicationStatus?
    var interval: Int? {
        if let status = publicationStatus {
            return Int(status.publish.publicationInterval.rounded())
        }
        return nil
    }
    
    var intervalState: ValueState { state(of: interval, type: ConfigModelPublicationStatus.self) }
    func getInterval() -> ValueState {
        if intervalState == .getsValue {
            var data = node.unicastAddress.data
            data.append(UInt16(0x1100).data)
            sendToNode(ConfigModelPublicationGet(parameters: data))
        }
        else { requestCompleted(for: ConfigModelPublicationStatus.self) }
        return intervalState
    }
    
    func setInterval(interval: Int) {
        guard let appKey = applicationKey else { return }
        let (steps, resolution) = interval <= UInt8.max ? (interval, StepResolution.seconds): (interval / 10, .tensOfSeconds)
        let newPublish = Publish(to: MeshAddress(0xC111),
                                 using: appKey,
                                 usingFriendshipMaterial: false,
                                 ttl: 6,
                                 periodSteps: UInt8(steps),
                                 periodResolution: resolution,
                                 retransmit: Publish.Retransmit(publishRetransmitCount: 0, intervalSteps: 50))
        guard let model = node.elements.first?.models.first else { fatalError() }
        sendToNode(ConfigModelPublicationSet(newPublish, to: model))
    }
    
    // Messaging.
    
    let kResendTimeOut = 10.0
    let kTimeOutCheckInterval = 5.0
    
    struct ActiveMessage {
        var message: MeshMessage
        var nextResendTime: CFAbsoluteTime
        var numResends: Int = 0
    }
    
    /// Contains the sent messages that we want a response to. They will be resent indefinitely if timed out.
    private var activeMessages = [UInt32: ActiveMessage]()

    private func sendToNode(_ message: MeshMessage?, resend: Bool = false) {

        guard let useMessage = message else { return }
        
        let now = CFAbsoluteTimeGetCurrent()
        
        // Resend of active message? Update entry.
        if activeMessages.containsMessage(useMessage) {
            if !resend { return }
            activeMessages[useMessage.opCode]?.nextResendTime = now + kResendTimeOut
            activeMessages[useMessage.opCode]?.numResends += 1
        }
        // New message replacing any older.
        else {
            let activeMessage = ActiveMessage(message: useMessage, nextResendTime: now + kResendTimeOut)
            activeMessages[useMessage.opCode] = activeMessage
        }
        
        do {
            if let configMessage = useMessage as? ConfigMessage {
                _ = try self.delegate?.send(configMessage, to: self.node.unicastAddress)
            }
            else {
                guard let appKey = self.applicationKey else { return }
                _ = try self.delegate?.send(useMessage, to: MeshAddress(self.node.unicastAddress), using: appKey)
            }
            
            if !resend {
                NSLog("Sent \(useMessage) to \(name)")
                updateActiveTimer()
            }
            else {
                NSLog("Resent \(useMessage) (count: \(activeMessages[useMessage.opCode]!.numResends)) to \(name)")
            }
        }
        catch { NSLog("Failed to send: \(error)") }
    }
    
    /// Helps to repeatedly check for timed out activeMessages.
    private var activeTimer: Timer?
    
    private func updateActiveTimer() {
        let types = activeMessages.map { type(of: $0.value.message) }
        NSLog("\(activeMessages.count) active messages for \(name): \(types)")
        
        // Stop repeating timer if no activeMessages.
        if activeMessages.count == 0 {
            activeTimer?.invalidate()
            activeTimer = nil
        }
        // ...else create it, if needed.
        else if activeTimer == nil {
            activeTimer = .scheduledTimer(withTimeInterval: kTimeOutCheckInterval, repeats: true) { [weak self] timer in
                let now = CFAbsoluteTimeGetCurrent()
                let timedOutMessages = self?.activeMessages.filter { now > $0.value.nextResendTime }.map { $0.value.message }
                timedOutMessages?.forEach { self?.sendToNode($0, resend: true) }
            }
            activeTimer?.tolerance = kTimeOutCheckInterval / 4
        }
    }
    
    func receivedFromNode(message: MeshMessage) {
        onMain {
            guard let message = message as? ResponseMessage else { return }
            
            if let sensorStatus = message as? SensorStatus {
                self.add(status: sensorStatus)
            }
            
            switch message {
            case let hslStatus as UbloxLightHSLStatus: self.lightHSL = hslStatus.color
            case let relayStatus as ConfigRelayStatus: self.relayOn = relayStatus.state == .enabled
            case let publicationStatus as ConfigModelPublicationStatus: self.publicationStatus = publicationStatus
            case is SensorStatus: break
            default: NSLog("Unexpected message: \(message) to \(self.name)")
            }
            
            // Remove corresponding request message.
            message.matchingRequestMessages.forEach {
                if self.activeMessages.removeMessage($0) {
                    self.updateActiveTimer()
                }
            }
            
            self.requestCompleted(for: type(of: message))
        }
    }
}

/// Functionality releted to sensor data storage.
extension UbloxNode {
    
    func removeOldEntries() {
        let oldestAllowedTimeStamp = CFAbsoluteTimeGetCurrent() - HistoryLimit.maxValue
        while statusEntries.count > 0 && statusEntries[0].timeStamp < oldestAllowedTimeStamp {
            statusEntries.removeFirst()
        }
    }
    
    static func decodeEntries(_ data: Data) throws -> [StatusEntry] {
        guard let uncompressedData = data.uncompressed() else { return [] }
        return try JSONDecoder().decode([StatusEntry].self, from: uncompressedData)
    }
    
    func readEntries() {
        do {
            guard let url = compressedURL else { return }
            guard let data = try? Data(contentsOf: url) else { return }
            statusEntries = try Self.decodeEntries(data)
            NSLog("Read node \(name): \(statusEntries.count) entries from \(data.count) bytes")
            removeOldEntries()
        }
        catch {
            NSLog("Failed to decode status entries: \(error)")
        }
    }
        
    var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(entriesKey + ".json")
    }
    
    var compressedURL: URL? { fileURL?.appendingPathExtension("zip") }
    
    enum SaveError: Error {
        case invalidURL
        case compressionFailed
    }
    
    static func encodeEntries(_ entries: [StatusEntry]) throws -> Data {
        let data = try JSONEncoder().encode(entries)
        guard let compressed = data.compressed() else { throw SaveError.compressionFailed }
        return compressed
    }
    
    @objc func saveData() {
        if readingCountSinceSync > 0 {
            do {
                guard let compressedURL = compressedURL else { throw SaveError.invalidURL }
                let data = try Self.encodeEntries(statusEntries)
                try data.write(to: compressedURL, options: .atomic)
                readingCountSinceSync = 0
                NSLog("Saved entry for \(name): \(statusEntries.count) entries in \(data.count) bytes")
            }
            catch {
                NSLog("Failed to encode status entries: \(error)")
            }
        }
    }
    
    func add(status: SensorStatus) {
        let entry = StatusEntry(status: status)
        statusEntries.append(entry)
        removeOldEntries()
        
        // Don't write too often, potential performance issues when scrolling for example with big meshes and tons of data.
        readingCountSinceSync += 1
        if readingCountSinceSync >= 256 {
            saveData()
        }
    }
}

extension UbloxNode: Equatable, Comparable {
    static func == (lhs: UbloxNode, rhs: UbloxNode) -> Bool {
        lhs.node.unicastAddress == rhs.node.unicastAddress
    }
    
    static func < (lhs: UbloxNode, rhs: UbloxNode) -> Bool {
        lhs.node.unicastAddress < rhs.node.unicastAddress
    }
}

extension Dictionary where Key == UInt32, Value == UbloxNode.ActiveMessage {
    
    func containsMessage(_ message: MeshMessage) -> Bool {
        self[message.opCode]?.message.equals(message) == true
    }
    
    func contains(opCodes: [UInt32]) -> Bool {
        self.filter { opCodes.contains($0.value.message.opCode) }.count > 0
    }
    
    mutating func removeMessage(_ message: MeshMessage) -> Bool {
        if containsMessage(message) || message is ConfigModelPublicationSet { // ConfigModelPublicationSet is currently not equatable because of periodSteps/periodResolution ambiguity.
            self.removeValue(forKey: message.opCode)
            return true
        }
        return false
    }
}
