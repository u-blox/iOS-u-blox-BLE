//
//  EncodingTests.swift
//  Tests
//
//  Created by Per Huss on 2020-02-11.
//  Copyright © 2020 U-blox. All rights reserved.
//

import XCTest
import nRFMeshProvision

@testable import U_blox

class MeshEncodingTests: XCTestCase {
    
    var meshHandler: MeshHandler!
    var peripheral: UbloxPeripheral!
    var node: UbloxNode!
    
    override func setUp() {
        peripheral = UbloxPeripheral(peripheral: nil)
        meshHandler = MeshHandler(peripheral: peripheral, settings: MeshSettings.basedOn(.c209))
        node = UbloxNode(node: nil, networkId: "", delegate: meshHandler.networkManager)
    }
    
    let manyStatuses = serverStatusesWith_Temp_Amb_Acc.map { $0.status }
    let fewStatuses = [serverStatusesWith_Temp_Amb_Acc.first!].map { $0.status }
    
    func testReceptionCount() {
        manyStatuses.forEach { node.add(status: $0) }
        XCTAssertEqual(node.statusEntries.count, manyStatuses.count)
    }

    private func encode(_ statuses: [SensorStatus]) -> Data? {
        statuses.forEach { node.add(status: $0) }
        do {
            let data = try UbloxNode.encodeEntries(node.statusEntries)
            XCTAssertTrue(data.count > 0)
            return data
        }
        catch { XCTFail() }
        return nil
    }
    
    private func decode(_ statuses: [SensorStatus]) {
        do {
            let data = encode(statuses)
            XCTAssertNotNil(data)
            let decodedStatuses = try UbloxNode.decodeEntries(data!).map { $0.status }
            XCTAssertEqual(statuses, decodedStatuses)
        }
        catch { XCTFail() }
    }
    
    func testEncodingFew() {
        _ = encode(fewStatuses)
    }
    
    func testDecodingFew() {
        decode(fewStatuses)
    }
    
    func testEncodingMany() {
        _ = encode(manyStatuses)
    }
    
    func testDecodingMany() {
        decode(manyStatuses)
    }
}
