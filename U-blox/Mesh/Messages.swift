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

struct Acceleration: CustomStringConvertible {
    var x, y, z: CGFloat
    var description: String { String(format: "acc: (x:%.2f, y:%.2f, z:%.2f)", x, y, z) }
}

/// Base class for sensor readings
class SensorStatus: StaticMeshMessage, CustomStringConvertible, Codable, Equatable {
    
    class var opCode: UInt32 { 0 }
    
    var parameters: Data?
    required init?(parameters: Data) { self.parameters = parameters }
    
    var description: String {
        var strs = [String]()
        if let deg = degreesCelsius { strs.append(String(format: "temp: %.1f", deg)) }
        if let hum = humidityPercent { strs.append(String(format: "hum: %.1f", hum)) }
        if let amb = ambientLightLux { strs.append(String(format: "amb: %.1f", amb)) }
        if let bar = milliBars { strs.append(String(format: "pres: %.0f", bar)) }
        if let acc = acceleration { strs.append(acc.description) }
        if let col = color { strs.append(col.description) }
        if let dat = parameters?.hex { strs.append("data: \"\(dat)\"") }
        return "\(Self.self): (" + strs.joined(separator: ", ") + ")"
    }
    
    var degreesCelsius: CGFloat? { nil }
    var humidityPercent: CGFloat? { nil }
    var ambientLightLux: CGFloat? { nil }
    var milliBars: CGFloat? { nil }
    var acceleration: Acceleration? { nil }
    var color: HSV<CGFloat>? { nil }
    
    enum CodingKeys: String, CodingKey {
        case opCode = "o"
        case parameters = "p"
    }
    
    enum SensorError: Error {
        case invalidOpCode
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tmpOpCode = try container.decode(UInt32.self, forKey: .opCode)
        if tmpOpCode != Self.opCode { throw SensorError.invalidOpCode }
        parameters = try container.decode(Data.self, forKey: .parameters)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.opCode, forKey: .opCode)
        try container.encode(parameters, forKey: .parameters)
    }
    
    static func == (lhs: SensorStatus, rhs: SensorStatus) -> Bool {
        lhs.opCode == rhs.opCode && lhs.parameters == rhs.parameters
    }
}

class SensorClientDelegate: ModelDelegate {
    var isSubscriptionSupported: Bool { true }
    var messageTypes: [UInt32 : MeshMessage.Type] { [:] }
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage, from source: Address, sentTo destination: MeshAddress) -> MeshMessage { fatalError() }
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage, from source: Address, sentTo destination: MeshAddress) { }
    func model(_ model: Model, didReceiveResponse response: MeshMessage, toAcknowledgedMessage request: AcknowledgedMeshMessage, from source: Address) { }
}

extension UInt32 {
    var data: Data { Data([UInt8(self & 0xff), UInt8((self >> 8) & 0xff), UInt8((self >> 16) & 0xff), UInt8(self >> 24)]) }
}

extension UInt16 {
    var data: Data { Data([UInt8(self & 0xff), UInt8(self >> 8)]) }
}

fileprivate extension Data {
    func uint32(_ offset: Int = 0) -> UInt32 { UInt32(self[offset + 3]) << 24 | uint24(offset) }
    func uint24(_ offset: Int = 0) -> UInt32 { UInt32(self[offset + 2]) << 16 | UInt32(uint16(offset)) }
    func uint16(_ offset: Int = 0) -> UInt16 { UInt16(self[offset + 1]) << 8  | UInt16(self[offset]) }
    func int16(_ offset: Int = 0)  -> Int16  { Int16(bitPattern: uint16(offset)) }
    func int8(_ offset: Int = 0)   -> Int8   { Int8(bitPattern: self[offset]) }
}

/// Generic Sensor Server used in C209
class SensorServerStatus: SensorStatus {
    override class var opCode: UInt32 { 0x0052 }
    
    enum PropertyID: UInt16 {
        case ambientLight = 0x004E
        case temperature = 0x004F
        case acceleration = 0xAAAA
    }
    
    /// Parses parameters according to Mesh Model Specification: 4.2.14 SensorStatus into a dictionary with PropertyID keys and Data values.
    private var dictionary: [PropertyID: Data]? {
        guard let data = parameters else { return nil }
        var dic = [PropertyID: Data]()
        var index = 0
        while index < data.count {
            let shortType = data[index] & 0x1 == 0
            let length = Int(data[index] >> 1) & (shortType ? 0xf: 0xff)
            let headerSize = shortType ? 2: 3
            guard data.count >= index + headerSize + length else { return nil }
            guard let propertyID = PropertyID(rawValue: shortType ?
                (UInt16(data[index]) >> 5) | (UInt16(data[index + 1]) << 3) :
                data.uint16(index + 1)) else { return nil }
            index += headerSize
            dic[propertyID] = Data(data[index..<index + length])
            index += length
        }
        return dic
    }

    override var ambientLightLux: CGFloat? {
        guard let data = dictionary?[.ambientLight], data.count == 3 else { return nil }
        let raw = data.uint24()
        return CGFloat(raw) / 100.0
    }
    
    override var degreesCelsius: CGFloat? {
        guard let data = dictionary?[.temperature], data.count == 1 else { return nil }
        let raw = data.int8()
        return CGFloat(raw) / 2.0
    }
    
    override var acceleration: Acceleration? {
        guard let data = dictionary?[.acceleration], data.count == 6 else { return nil }
        let rawX = data.int16(0)
        let rawY = data.int16(2)
        let rawZ = data.int16(4)
        return Acceleration(x: CGFloat(rawX) / 1024,
                            y: CGFloat(rawY) / 1024,
                            z: CGFloat(rawZ) / 1024) }
}

public struct SensorServerGet: AcknowledgedGenericMessage {
    var type: SensorServerStatus.PropertyID?
    public var parameters: Data? { type?.rawValue.data }
    init() { }
    public init?(parameters: Data) { type = SensorServerStatus.PropertyID(rawValue: parameters.uint16()) }
    init(type: SensorServerStatus.PropertyID) { self.type = type }
    public static let opCode: UInt32 = 0x8231
    public static let responseType: StaticMeshMessage.Type = SensorServerStatus.self
}

class SensorServerClientDelegate: SensorClientDelegate {
    override var messageTypes: [UInt32: MeshMessage.Type] { [ SensorServerStatus.self ].toMap() }
}

/// Simple Sensor handling, used in office mesh.
public struct SimpleSensorGet: AcknowledgedGenericMessage {
    public var parameters: Data? { Data() }
    init() { }
    public init?(parameters: Data) { }
    public static let opCode: UInt32 = 0xD80059
    public static let responseType: StaticMeshMessage.Type = SimpleSensorStatus.self
}

class SimpleSensorStatus: SensorStatus, StaticVendorMessage {
    
    override class var opCode: UInt32 { 0xD70059 }
    
    private var rawAccelerometer: UInt8 { parameters![0] }
    private var rawHumidityPercent: UInt8 { parameters![1] }
    private var rawTemperatureCWhole: UInt8 { parameters![2] }
    private var rawTemperatureCTenths: Int8 { Int8(bitPattern: parameters![3]) }
    private var rawAmbientLightPercent: UInt8 { parameters![4] }
    private var rawBarometerWholeDiff: Int8 { Int8(bitPattern: parameters![5]) }
    private var rawBarometerTenths: Int8 { Int8(bitPattern: parameters![6]) }
    
    override var acceleration: Acceleration { Acceleration(x: CGFloat(100 - rawAccelerometer) / 100, y: 0, z: CGFloat(rawAccelerometer) / 100) }
    override var degreesCelsius: CGFloat { CGFloat(rawTemperatureCWhole) + CGFloat(rawTemperatureCTenths) / 10.0 }
    override var humidityPercent: CGFloat { CGFloat(rawHumidityPercent) }
    override var milliBars: CGFloat { 1000.0 + CGFloat(rawBarometerWholeDiff) + CGFloat(rawBarometerTenths) }
    override var ambientLightLux: CGFloat { CGFloat(rawAmbientLightPercent) }
}

class SimpleSensorClientDelegate: SensorClientDelegate {
    override var messageTypes: [UInt32 : MeshMessage.Type] { [ SimpleSensorStatus.self ].toMap() }
}

/// GenericOnOff handling
class GenericOnOffClientDelegate: SensorClientDelegate {
    override var messageTypes: [UInt32: MeshMessage.Type] { [ GenericOnOffStatus.self ].toMap() }
    override var isSubscriptionSupported: Bool { false }
}

// Light HSL

class UbloxLightHSLStatus: SensorStatus {
    override class var opCode: UInt32 { 0x8278 }
    
    private var rawLightness: UInt16 { UInt16(parameters![1]) << 8 | UInt16(parameters![0]) }
    private var rawHue: UInt16 { UInt16(parameters![3]) << 8 | UInt16(parameters![2]) }
    private var rawSaturation: UInt16 { UInt16(parameters![5]) << 8 | UInt16(parameters![4]) }
    private var rawRemainingTime: UInt8? { parameters!.count >= 7 ? parameters![6] : nil }
    
    override var color: HSV<CGFloat>? { HSV(hue: CGFloat(rawHue) / CGFloat(UInt16.max),
                                            saturation: CGFloat(rawSaturation) / CGFloat(UInt16.max),
                                            brightness: CGFloat(rawLightness) / CGFloat(UInt16.max),
                                            alpha: 1) }
}

class LightHSLServerClientDelegate: SensorClientDelegate {
    override var messageTypes: [UInt32 : MeshMessage.Type] { [ UbloxLightHSLStatus.self ].toMap() }
}

struct UbloxLightHSLGet: AcknowledgedGenericMessage {
    static let opCode: UInt32 = 0x826D
    static let responseType: StaticMeshMessage.Type = UbloxLightHSLStatus.self
    
    var parameters: Data? { nil }
    
    public init() { }
    init?(parameters: Data) { guard parameters.isEmpty else { return nil } }
}

public struct UbloxLightHSLSet: AcknowledgedGenericMessage, TransactionMessage {
    public static let opCode: UInt32 = 0x8276
    public static let responseType: StaticMeshMessage.Type = UbloxLightHSLStatus.self
    
    public var tid: UInt8!
    
    public var parameters: Data? {
        let l = UInt16((color.brightness * CGFloat(UInt16.max)).rounded())
        let h = UInt16((color.hue * CGFloat(UInt16.max)).rounded())
        let s = UInt16((color.saturation * CGFloat(UInt16.max)).rounded())
        var data = Data([UInt8(l & 0xff), UInt8(l >> 8),
                         UInt8(h & 0xff), UInt8(h >> 8),
                         UInt8(s & 0xff), UInt8(s >> 8)])
        if tid != nil { data.append(contentsOf: [tid!]) }
        return data
    }
    
    let color: HSV<CGFloat>
        
    init(_ color: HSV<CGFloat>) { self.color = color }
    
    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 6 else { return nil }
        guard let tmpStatus = UbloxLightHSLStatus(parameters: parameters[...5]) else { return nil }
        guard let tmpColor = tmpStatus.color else { return nil }
        color = tmpColor
        if parameters.count == 7 {
            tid = parameters[6]
        }
    }
}

// Adopting the ResponseMessage protocol for status messages lets us check if a response matches a particular request.

protocol ResponseMessage: StaticMeshMessage {
    var matchingRequestMessages: [StaticAcknowledgedMeshMessage] { get }
    static var matchingRequestOpCodes: [UInt32] { get }
}

extension UbloxLightHSLStatus: ResponseMessage {
    static let matchingRequestOpCodes: [UInt32] = [UbloxLightHSLGet.opCode, UbloxLightHSLSet.opCode]
    var matchingRequestMessages: [StaticAcknowledgedMeshMessage] {
        [UbloxLightHSLGet(), UbloxLightHSLSet(parameters: parameters!)!]
    }
}

extension ConfigRelayStatus: ResponseMessage {
    static let matchingRequestOpCodes: [UInt32] = [ConfigRelayGet.opCode, ConfigRelaySet.opCode]
    var matchingRequestMessages: [StaticAcknowledgedMeshMessage] {
        let setMessage = self.state == .notEnabled ? ConfigRelaySet(): ConfigRelaySet(count: count, steps: steps)
        return [ConfigRelayGet(), setMessage]
    }
}

extension ConfigModelPublicationStatus: ResponseMessage {
    static let matchingRequestOpCodes: [UInt32] = [ConfigModelPublicationGet.opCode, ConfigModelPublicationSet.opCode]
    var matchingRequestMessages: [StaticAcknowledgedMeshMessage] {
        var data = elementAddress.data
        data.append(UInt16(0x1100).data)
        let getMessage = ConfigModelPublicationGet(parameters: data)!
        
        let setParams = Data(parameters![1...])
        let setMessage = ConfigModelPublicationSet(parameters: setParams)!
        
        return [getMessage, setMessage]
    }
}

extension SensorServerStatus: ResponseMessage {
    static let matchingRequestOpCodes: [UInt32] = [SensorServerGet.opCode]
    var matchingRequestMessages: [StaticAcknowledgedMeshMessage] {
        [SensorServerGet()]
    }
}

extension SimpleSensorStatus: ResponseMessage {
    static let matchingRequestOpCodes: [UInt32] = [SimpleSensorGet.opCode]
    var matchingRequestMessages: [StaticAcknowledgedMeshMessage] {
        [SimpleSensorGet()]
    }
}

extension MeshMessage {
    private var hash: Data { opCode.data + (parameters ?? Data()) }
    func equals(_ other: MeshMessage) -> Bool { hash == other.hash }
}
