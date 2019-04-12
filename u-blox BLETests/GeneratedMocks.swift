// MARK: - Mocks generated from file: U-blox/Models/UbloxPeripheral.swift at 2019-01-15 10:09:18 +0000


import Cuckoo
@testable import U_blox

import CoreBluetooth
import Foundation

class MockUbloxPeripheral: UbloxPeripheral, Cuckoo.ClassMock {
    typealias MocksType = UbloxPeripheral
    typealias Stubbing = __StubbingProxy_UbloxPeripheral
    typealias Verification = __VerificationProxy_UbloxPeripheral

    private var __defaultImplStub: UbloxPeripheral?

    let cuckoo_manager = Cuckoo.MockManager.preconfiguredManager ?? Cuckoo.MockManager(hasParent: true)

    func enableDefaultImplementation(_ stub: UbloxPeripheral) {
        __defaultImplStub = stub
        cuckoo_manager.enableDefaultStubImplementation()
    }

    
    
     override var cbPeripheral: CBPeripheral? {
        get {
            return cuckoo_manager.getter("cbPeripheral",
                superclassCall:
                    
                    super.cbPeripheral
                    ,
                defaultCall: __defaultImplStub!.cbPeripheral)
        }
        
        set {
            cuckoo_manager.setter("cbPeripheral",
                value: newValue,
                superclassCall:
                    
                    super.cbPeripheral = newValue
                    ,
                defaultCall: __defaultImplStub!.cbPeripheral = newValue)
        }
        
    }
    
    
     override var name: String? {
        get {
            return cuckoo_manager.getter("name",
                superclassCall:
                    
                    super.name
                    ,
                defaultCall: __defaultImplStub!.name)
        }
        
    }
    
    
     override var services: [CBService] {
        get {
            return cuckoo_manager.getter("services",
                superclassCall:
                    
                    super.services
                    ,
                defaultCall: __defaultImplStub!.services)
        }
        
    }
    
    
     override var isSupportingSerialPort: Bool {
        get {
            return cuckoo_manager.getter("isSupportingSerialPort",
                superclassCall:
                    
                    super.isSupportingSerialPort
                    ,
                defaultCall: __defaultImplStub!.isSupportingSerialPort)
        }
        
    }
    
    
     override var serialPortService: CBService? {
        get {
            return cuckoo_manager.getter("serialPortService",
                superclassCall:
                    
                    super.serialPortService
                    ,
                defaultCall: __defaultImplStub!.serialPortService)
        }
        
    }
    
    
     override var state: CBPeripheralState {
        get {
            return cuckoo_manager.getter("state",
                superclassCall:
                    
                    super.state
                    ,
                defaultCall: __defaultImplStub!.state)
        }
        
    }
    
    
     override var maximumWriteValueLength: Int {
        get {
            return cuckoo_manager.getter("maximumWriteValueLength",
                superclassCall:
                    
                    super.maximumWriteValueLength
                    ,
                defaultCall: __defaultImplStub!.maximumWriteValueLength)
        }
        
    }
    
    
     override var rssi: NSNumber? {
        get {
            return cuckoo_manager.getter("rssi",
                superclassCall:
                    
                    super.rssi
                    ,
                defaultCall: __defaultImplStub!.rssi)
        }
        
        set {
            cuckoo_manager.setter("rssi",
                value: newValue,
                superclassCall:
                    
                    super.rssi = newValue
                    ,
                defaultCall: __defaultImplStub!.rssi = newValue)
        }
        
    }
    
    
     override var identifier: UUID {
        get {
            return cuckoo_manager.getter("identifier",
                superclassCall:
                    
                    super.identifier
                    ,
                defaultCall: __defaultImplStub!.identifier)
        }
        
    }
    

    

    
    // ["name": "write", "returnSignature": "", "fullyQualifiedName": "write(bytes: [Byte], for: UbloxCharacteristic, type: CBCharacteristicWriteType)", "parameterSignature": "bytes: [Byte], for ubloxCharacteristic: UbloxCharacteristic, type: CBCharacteristicWriteType", "parameterSignatureWithoutNames": "bytes: [Byte], ubloxCharacteristic: UbloxCharacteristic, type: CBCharacteristicWriteType", "inputTypes": "[Byte], UbloxCharacteristic, CBCharacteristicWriteType", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "bytes, ubloxCharacteristic, type", "call": "bytes: bytes, for: ubloxCharacteristic, type: type", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("bytes"), name: "bytes", type: "[Byte]", range: CountableRange(1662..<1675), nameRange: CountableRange(1662..<1667)), CuckooGeneratorFramework.MethodParameter(label: Optional("for"), name: "ubloxCharacteristic", type: "UbloxCharacteristic", range: CountableRange(1677..<1721), nameRange: CountableRange(1677..<1680)), CuckooGeneratorFramework.MethodParameter(label: Optional("type"), name: "type", type: "CBCharacteristicWriteType", range: CountableRange(1723..<1773), nameRange: CountableRange(1723..<1727))], "returnType": "Void", "isOptional": false, "escapingParameterNames": "bytes, ubloxCharacteristic, type", "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func write(bytes: [Byte], for ubloxCharacteristic: UbloxCharacteristic, type: CBCharacteristicWriteType)  {
        
            return cuckoo_manager.call("write(bytes: [Byte], for: UbloxCharacteristic, type: CBCharacteristicWriteType)",
                parameters: (bytes, ubloxCharacteristic, type),
                escapingParameters: (bytes, ubloxCharacteristic, type),
                superclassCall:
                    
                    super.write(bytes: bytes, for: ubloxCharacteristic, type: type)
                    ,
                defaultCall: __defaultImplStub!.write(bytes: bytes, for: ubloxCharacteristic, type: type))
        
    }
    
    // ["name": "discoverServices", "returnSignature": "", "fullyQualifiedName": "discoverServices(_: [CBUUID]?)", "parameterSignature": "_ serviceUUIDs: [CBUUID]?", "parameterSignatureWithoutNames": "serviceUUIDs: [CBUUID]?", "inputTypes": "[CBUUID]?", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "serviceUUIDs", "call": "serviceUUIDs", "parameters": [CuckooGeneratorFramework.MethodParameter(label: nil, name: "serviceUUIDs", type: "[CBUUID]?", range: CountableRange(2065..<2090), nameRange: CountableRange(0..<0))], "returnType": "Void", "isOptional": false, "escapingParameterNames": "serviceUUIDs", "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func discoverServices(_ serviceUUIDs: [CBUUID]?)  {
        
            return cuckoo_manager.call("discoverServices(_: [CBUUID]?)",
                parameters: (serviceUUIDs),
                escapingParameters: (serviceUUIDs),
                superclassCall:
                    
                    super.discoverServices(serviceUUIDs)
                    ,
                defaultCall: __defaultImplStub!.discoverServices(serviceUUIDs))
        
    }
    
    // ["name": "discoverCharacteristics", "returnSignature": "", "fullyQualifiedName": "discoverCharacteristics(_: [CBUUID]?, for: CBService)", "parameterSignature": "_ characteristicUUIDs: [CBUUID]?, for service: CBService", "parameterSignatureWithoutNames": "characteristicUUIDs: [CBUUID]?, service: CBService", "inputTypes": "[CBUUID]?, CBService", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "characteristicUUIDs, service", "call": "characteristicUUIDs, for: service", "parameters": [CuckooGeneratorFramework.MethodParameter(label: nil, name: "characteristicUUIDs", type: "[CBUUID]?", range: CountableRange(2191..<2223), nameRange: CountableRange(0..<0)), CuckooGeneratorFramework.MethodParameter(label: Optional("for"), name: "service", type: "CBService", range: CountableRange(2225..<2247), nameRange: CountableRange(2225..<2228))], "returnType": "Void", "isOptional": false, "escapingParameterNames": "characteristicUUIDs, service", "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)  {
        
            return cuckoo_manager.call("discoverCharacteristics(_: [CBUUID]?, for: CBService)",
                parameters: (characteristicUUIDs, service),
                escapingParameters: (characteristicUUIDs, service),
                superclassCall:
                    
                    super.discoverCharacteristics(characteristicUUIDs, for: service)
                    ,
                defaultCall: __defaultImplStub!.discoverCharacteristics(characteristicUUIDs, for: service))
        
    }
    
    // ["name": "setNotify", "returnSignature": "", "fullyQualifiedName": "setNotify(_: Bool, for: CBCharacteristic?)", "parameterSignature": "_ enabled: Bool, for characteristic: CBCharacteristic?", "parameterSignatureWithoutNames": "enabled: Bool, characteristic: CBCharacteristic?", "inputTypes": "Bool, CBCharacteristic?", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "enabled, characteristic", "call": "enabled, for: characteristic", "parameters": [CuckooGeneratorFramework.MethodParameter(label: nil, name: "enabled", type: "Bool", range: CountableRange(2361..<2376), nameRange: CountableRange(0..<0)), CuckooGeneratorFramework.MethodParameter(label: Optional("for"), name: "characteristic", type: "CBCharacteristic?", range: CountableRange(2378..<2415), nameRange: CountableRange(2378..<2381))], "returnType": "Void", "isOptional": false, "escapingParameterNames": "enabled, characteristic", "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func setNotify(_ enabled: Bool, for characteristic: CBCharacteristic?)  {
        
            return cuckoo_manager.call("setNotify(_: Bool, for: CBCharacteristic?)",
                parameters: (enabled, characteristic),
                escapingParameters: (enabled, characteristic),
                superclassCall:
                    
                    super.setNotify(enabled, for: characteristic)
                    ,
                defaultCall: __defaultImplStub!.setNotify(enabled, for: characteristic))
        
    }
    
    // ["name": "readValue", "returnSignature": "", "fullyQualifiedName": "readValue(for: CBCharacteristic)", "parameterSignature": "for characteristic: CBCharacteristic", "parameterSignatureWithoutNames": "characteristic: CBCharacteristic", "inputTypes": "CBCharacteristic", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "characteristic", "call": "for: characteristic", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("for"), name: "characteristic", type: "CBCharacteristic", range: CountableRange(2602..<2638), nameRange: CountableRange(2602..<2605))], "returnType": "Void", "isOptional": false, "escapingParameterNames": "characteristic", "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func readValue(for characteristic: CBCharacteristic)  {
        
            return cuckoo_manager.call("readValue(for: CBCharacteristic)",
                parameters: (characteristic),
                escapingParameters: (characteristic),
                superclassCall:
                    
                    super.readValue(for: characteristic)
                    ,
                defaultCall: __defaultImplStub!.readValue(for: characteristic))
        
    }
    
    // ["name": "write", "returnSignature": "", "fullyQualifiedName": "write(_: Data, for: CBCharacteristic?, type: CBCharacteristicWriteType)", "parameterSignature": "_ data: Data, for characteristic: CBCharacteristic?, type: CBCharacteristicWriteType", "parameterSignatureWithoutNames": "data: Data, characteristic: CBCharacteristic?, type: CBCharacteristicWriteType", "inputTypes": "Data, CBCharacteristic?, CBCharacteristicWriteType", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "data, characteristic, type", "call": "data, for: characteristic, type: type", "parameters": [CuckooGeneratorFramework.MethodParameter(label: nil, name: "data", type: "Data", range: CountableRange(2721..<2733), nameRange: CountableRange(0..<0)), CuckooGeneratorFramework.MethodParameter(label: Optional("for"), name: "characteristic", type: "CBCharacteristic?", range: CountableRange(2735..<2772), nameRange: CountableRange(2735..<2738)), CuckooGeneratorFramework.MethodParameter(label: Optional("type"), name: "type", type: "CBCharacteristicWriteType", range: CountableRange(2774..<2805), nameRange: CountableRange(2774..<2778))], "returnType": "Void", "isOptional": false, "escapingParameterNames": "data, characteristic, type", "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func write(_ data: Data, for characteristic: CBCharacteristic?, type: CBCharacteristicWriteType)  {
        
            return cuckoo_manager.call("write(_: Data, for: CBCharacteristic?, type: CBCharacteristicWriteType)",
                parameters: (data, characteristic, type),
                escapingParameters: (data, characteristic, type),
                superclassCall:
                    
                    super.write(data, for: characteristic, type: type)
                    ,
                defaultCall: __defaultImplStub!.write(data, for: characteristic, type: type))
        
    }
    

	struct __StubbingProxy_UbloxPeripheral: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    var cbPeripheral: Cuckoo.ClassToBeStubbedProperty<MockUbloxPeripheral, CBPeripheral?> {
	        return .init(manager: cuckoo_manager, name: "cbPeripheral")
	    }
	    
	    var name: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, String?> {
	        return .init(manager: cuckoo_manager, name: "name")
	    }
	    
	    var services: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, [CBService]> {
	        return .init(manager: cuckoo_manager, name: "services")
	    }
	    
	    var isSupportingSerialPort: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, Bool> {
	        return .init(manager: cuckoo_manager, name: "isSupportingSerialPort")
	    }
	    
	    var serialPortService: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, CBService?> {
	        return .init(manager: cuckoo_manager, name: "serialPortService")
	    }
	    
	    var state: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, CBPeripheralState> {
	        return .init(manager: cuckoo_manager, name: "state")
	    }
	    
	    var maximumWriteValueLength: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, Int> {
	        return .init(manager: cuckoo_manager, name: "maximumWriteValueLength")
	    }
	    
	    var rssi: Cuckoo.ClassToBeStubbedProperty<MockUbloxPeripheral, NSNumber?> {
	        return .init(manager: cuckoo_manager, name: "rssi")
	    }
	    
	    var identifier: Cuckoo.ClassToBeStubbedReadOnlyProperty<MockUbloxPeripheral, UUID> {
	        return .init(manager: cuckoo_manager, name: "identifier")
	    }
	    
	    
	    func write<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable, M3: Cuckoo.Matchable>(bytes: M1, for ubloxCharacteristic: M2, type: M3) -> Cuckoo.ClassStubNoReturnFunction<([Byte], UbloxCharacteristic, CBCharacteristicWriteType)> where M1.MatchedType == [Byte], M2.MatchedType == UbloxCharacteristic, M3.MatchedType == CBCharacteristicWriteType {
	        let matchers: [Cuckoo.ParameterMatcher<([Byte], UbloxCharacteristic, CBCharacteristicWriteType)>] = [wrap(matchable: bytes) { $0.0 }, wrap(matchable: ubloxCharacteristic) { $0.1 }, wrap(matchable: type) { $0.2 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockUbloxPeripheral.self, method: "write(bytes: [Byte], for: UbloxCharacteristic, type: CBCharacteristicWriteType)", parameterMatchers: matchers))
	    }
	    
	    func discoverServices<M1: Cuckoo.Matchable>(_ serviceUUIDs: M1) -> Cuckoo.ClassStubNoReturnFunction<([CBUUID]?)> where M1.MatchedType == [CBUUID]? {
	        let matchers: [Cuckoo.ParameterMatcher<([CBUUID]?)>] = [wrap(matchable: serviceUUIDs) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockUbloxPeripheral.self, method: "discoverServices(_: [CBUUID]?)", parameterMatchers: matchers))
	    }
	    
	    func discoverCharacteristics<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable>(_ characteristicUUIDs: M1, for service: M2) -> Cuckoo.ClassStubNoReturnFunction<([CBUUID]?, CBService)> where M1.MatchedType == [CBUUID]?, M2.MatchedType == CBService {
	        let matchers: [Cuckoo.ParameterMatcher<([CBUUID]?, CBService)>] = [wrap(matchable: characteristicUUIDs) { $0.0 }, wrap(matchable: service) { $0.1 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockUbloxPeripheral.self, method: "discoverCharacteristics(_: [CBUUID]?, for: CBService)", parameterMatchers: matchers))
	    }
	    
	    func setNotify<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable>(_ enabled: M1, for characteristic: M2) -> Cuckoo.ClassStubNoReturnFunction<(Bool, CBCharacteristic?)> where M1.MatchedType == Bool, M2.MatchedType == CBCharacteristic? {
	        let matchers: [Cuckoo.ParameterMatcher<(Bool, CBCharacteristic?)>] = [wrap(matchable: enabled) { $0.0 }, wrap(matchable: characteristic) { $0.1 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockUbloxPeripheral.self, method: "setNotify(_: Bool, for: CBCharacteristic?)", parameterMatchers: matchers))
	    }
	    
	    func readValue<M1: Cuckoo.Matchable>(for characteristic: M1) -> Cuckoo.ClassStubNoReturnFunction<(CBCharacteristic)> where M1.MatchedType == CBCharacteristic {
	        let matchers: [Cuckoo.ParameterMatcher<(CBCharacteristic)>] = [wrap(matchable: characteristic) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockUbloxPeripheral.self, method: "readValue(for: CBCharacteristic)", parameterMatchers: matchers))
	    }
	    
	    func write<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable, M3: Cuckoo.Matchable>(_ data: M1, for characteristic: M2, type: M3) -> Cuckoo.ClassStubNoReturnFunction<(Data, CBCharacteristic?, CBCharacteristicWriteType)> where M1.MatchedType == Data, M2.MatchedType == CBCharacteristic?, M3.MatchedType == CBCharacteristicWriteType {
	        let matchers: [Cuckoo.ParameterMatcher<(Data, CBCharacteristic?, CBCharacteristicWriteType)>] = [wrap(matchable: data) { $0.0 }, wrap(matchable: characteristic) { $0.1 }, wrap(matchable: type) { $0.2 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockUbloxPeripheral.self, method: "write(_: Data, for: CBCharacteristic?, type: CBCharacteristicWriteType)", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_UbloxPeripheral: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	    var cbPeripheral: Cuckoo.VerifyProperty<CBPeripheral?> {
	        return .init(manager: cuckoo_manager, name: "cbPeripheral", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var name: Cuckoo.VerifyReadOnlyProperty<String?> {
	        return .init(manager: cuckoo_manager, name: "name", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var services: Cuckoo.VerifyReadOnlyProperty<[CBService]> {
	        return .init(manager: cuckoo_manager, name: "services", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var isSupportingSerialPort: Cuckoo.VerifyReadOnlyProperty<Bool> {
	        return .init(manager: cuckoo_manager, name: "isSupportingSerialPort", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var serialPortService: Cuckoo.VerifyReadOnlyProperty<CBService?> {
	        return .init(manager: cuckoo_manager, name: "serialPortService", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var state: Cuckoo.VerifyReadOnlyProperty<CBPeripheralState> {
	        return .init(manager: cuckoo_manager, name: "state", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var maximumWriteValueLength: Cuckoo.VerifyReadOnlyProperty<Int> {
	        return .init(manager: cuckoo_manager, name: "maximumWriteValueLength", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var rssi: Cuckoo.VerifyProperty<NSNumber?> {
	        return .init(manager: cuckoo_manager, name: "rssi", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	    var identifier: Cuckoo.VerifyReadOnlyProperty<UUID> {
	        return .init(manager: cuckoo_manager, name: "identifier", callMatcher: callMatcher, sourceLocation: sourceLocation)
	    }
	    
	
	    
	    @discardableResult
	    func write<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable, M3: Cuckoo.Matchable>(bytes: M1, for ubloxCharacteristic: M2, type: M3) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [Byte], M2.MatchedType == UbloxCharacteristic, M3.MatchedType == CBCharacteristicWriteType {
	        let matchers: [Cuckoo.ParameterMatcher<([Byte], UbloxCharacteristic, CBCharacteristicWriteType)>] = [wrap(matchable: bytes) { $0.0 }, wrap(matchable: ubloxCharacteristic) { $0.1 }, wrap(matchable: type) { $0.2 }]
	        return cuckoo_manager.verify("write(bytes: [Byte], for: UbloxCharacteristic, type: CBCharacteristicWriteType)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func discoverServices<M1: Cuckoo.Matchable>(_ serviceUUIDs: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [CBUUID]? {
	        let matchers: [Cuckoo.ParameterMatcher<([CBUUID]?)>] = [wrap(matchable: serviceUUIDs) { $0 }]
	        return cuckoo_manager.verify("discoverServices(_: [CBUUID]?)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func discoverCharacteristics<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable>(_ characteristicUUIDs: M1, for service: M2) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [CBUUID]?, M2.MatchedType == CBService {
	        let matchers: [Cuckoo.ParameterMatcher<([CBUUID]?, CBService)>] = [wrap(matchable: characteristicUUIDs) { $0.0 }, wrap(matchable: service) { $0.1 }]
	        return cuckoo_manager.verify("discoverCharacteristics(_: [CBUUID]?, for: CBService)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func setNotify<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable>(_ enabled: M1, for characteristic: M2) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == Bool, M2.MatchedType == CBCharacteristic? {
	        let matchers: [Cuckoo.ParameterMatcher<(Bool, CBCharacteristic?)>] = [wrap(matchable: enabled) { $0.0 }, wrap(matchable: characteristic) { $0.1 }]
	        return cuckoo_manager.verify("setNotify(_: Bool, for: CBCharacteristic?)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func readValue<M1: Cuckoo.Matchable>(for characteristic: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == CBCharacteristic {
	        let matchers: [Cuckoo.ParameterMatcher<(CBCharacteristic)>] = [wrap(matchable: characteristic) { $0 }]
	        return cuckoo_manager.verify("readValue(for: CBCharacteristic)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func write<M1: Cuckoo.Matchable, M2: Cuckoo.Matchable, M3: Cuckoo.Matchable>(_ data: M1, for characteristic: M2, type: M3) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == Data, M2.MatchedType == CBCharacteristic?, M3.MatchedType == CBCharacteristicWriteType {
	        let matchers: [Cuckoo.ParameterMatcher<(Data, CBCharacteristic?, CBCharacteristicWriteType)>] = [wrap(matchable: data) { $0.0 }, wrap(matchable: characteristic) { $0.1 }, wrap(matchable: type) { $0.2 }]
	        return cuckoo_manager.verify("write(_: Data, for: CBCharacteristic?, type: CBCharacteristicWriteType)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class UbloxPeripheralStub: UbloxPeripheral {
    
     override var cbPeripheral: CBPeripheral? {
        get {
            return DefaultValueRegistry.defaultValue(for: (CBPeripheral?).self)
        }
        
        set { }
        
    }
    
     override var name: String? {
        get {
            return DefaultValueRegistry.defaultValue(for: (String?).self)
        }
        
    }
    
     override var services: [CBService] {
        get {
            return DefaultValueRegistry.defaultValue(for: ([CBService]).self)
        }
        
    }
    
     override var isSupportingSerialPort: Bool {
        get {
            return DefaultValueRegistry.defaultValue(for: (Bool).self)
        }
        
    }
    
     override var serialPortService: CBService? {
        get {
            return DefaultValueRegistry.defaultValue(for: (CBService?).self)
        }
        
    }
    
     override var state: CBPeripheralState {
        get {
            return DefaultValueRegistry.defaultValue(for: (CBPeripheralState).self)
        }
        
    }
    
     override var maximumWriteValueLength: Int {
        get {
            return DefaultValueRegistry.defaultValue(for: (Int).self)
        }
        
    }
    
     override var rssi: NSNumber? {
        get {
            return DefaultValueRegistry.defaultValue(for: (NSNumber?).self)
        }
        
        set { }
        
    }
    
     override var identifier: UUID {
        get {
            return DefaultValueRegistry.defaultValue(for: (UUID).self)
        }
        
    }
    

    

    
     override func write(bytes: [Byte], for ubloxCharacteristic: UbloxCharacteristic, type: CBCharacteristicWriteType)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     override func discoverServices(_ serviceUUIDs: [CBUUID]?)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     override func setNotify(_ enabled: Bool, for characteristic: CBCharacteristic?)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     override func readValue(for characteristic: CBCharacteristic)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     override func write(_ data: Data, for characteristic: CBCharacteristic?, type: CBCharacteristicWriteType)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}

