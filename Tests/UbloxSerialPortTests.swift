//
//  UbloxSerialPortTests.swift
//  u-blox BLETests
//
//  Created by Groneng Tobias on 2018-04-12.
//  Copyright © 2018 U-blox. All rights reserved.
//

import XCTest
import CoreBluetooth
import Cuckoo
@testable import U_blox

class UbloxSerialPortTests: XCTestCase {
    let sps = CBMutableService(type: UbloxService.serialPort.cbUuid, primary: true)
    let fifo = CBMutableCharacteristic(type: UbloxCharacteristic.serialPortFifo.cbUuid, properties: [.write, .read, .writeWithoutResponse, .notify, .indicate], value: nil, permissions: [.readable, .writeable])
    let credits = CBMutableCharacteristic(type: UbloxCharacteristic.serialPortCredits.cbUuid, properties: [.write, .read, .writeWithoutResponse, .notify, .indicate], value: nil, permissions: [.readable, .writeable])
    
    var peripheral: MockUbloxPeripheral!
    var serialPort: UbloxSerialPort!
    
    override func setUp() {
        peripheral = MockUbloxPeripheral(peripheral: nil)
        serialPort = UbloxSerialPort(peripheral: peripheral)
        
        stub (peripheral) { mocked in
            when(mocked.discoverServices(equal(to: nil))).then { services in
                self.serialPort.processDidDiscoverServices(nil)
            }
            when(mocked.discoverCharacteristics(equal(to: nil), for: equal(to: sps))).then { characs, service in
                self.serialPort.processDidDiscoverCharacteristicsFor(service, error: nil)
            }
            when(mocked.setNotify(any(), for: any())).thenDoNothing()
            when(mocked.write(any(), for: any(), type: any())).thenDoNothing()
            when(mocked.maximumWriteValueLength.get).thenReturn(244)
            when(mocked.state.get).thenReturn(.connected)
        }
        
        super.setUp()
    }
    
    func testErrorStateWhenNoSpsService() {
        withNoService()
        
        let state = MockStateDelegate()
        serialPort.delegate = state
        serialPort.open()
        XCTAssertEqual(state.stateSequence, [.waitServiceSearch, .error])
    }
    
    func testErrorStateWhenSpsServiceIncomplete() {
        withHalfService()
        
        let state = MockStateDelegate()
        serialPort.delegate = state
        serialPort.open()
        XCTAssertEqual(state.stateSequence, [.waitServiceSearch, .waitCharacteristicSearch, .error])
    }
    
    func testStateIsOpenWhenNoCredits() {
        withFullService()
        
        let state = MockStateDelegate()
        serialPort.delegate = state
        serialPort.withFlowControl = false
        serialPort.open()
        XCTAssertEqual(state.stateSequence, [.waitServiceSearch, .waitCharacteristicSearch, .open])
    }
    
    func testStateWaitingOnCreditsWhenCredits() {
        withFullService()
        
        let state = MockStateDelegate()
        serialPort.delegate = state
        serialPort.open()
        XCTAssertEqual(state.stateSequence, [.waitServiceSearch, .waitCharacteristicSearch, .waitInitialTxCredits])
    }
    
    func testSubscribeFifoNotificationWhenNoCredits() {
        withFullService()
        
        serialPort.withFlowControl = false
        serialPort.open()
        
        verify(peripheral, times(1)).setNotify(true, for: equal(to: fifo))
    }
    
    func testDoNotSubscribeCreditsWhenNoCredits() {
        withFullService()
        
        serialPort.withFlowControl = false
        serialPort.open()
        
        verify(peripheral, never()).setNotify(true, for: equal(to: credits))
    }
    
    func testSubscribeFifoWhenCredits() {
        withFullService()
        
        serialPort.open()
        
        verify(peripheral, times(1)).setNotify(true, for: equal(to: fifo))
    }
    
    func testSubscribeCreditsWhenCredits() {
        withFullService()
        
        serialPort.open()
        
        verify(peripheral, times(1)).setNotify(true, for: equal(to: credits))
    }
    
    func testWriteCreditsWhenCredits() {
        withFullService()
        
        serialPort.open()
        
        verify(peripheral, times(1)).write(equal(to: Data([32])), for: equal(to: credits), type:  any())
    }
    
    func testStateOpenWhenReceivingCreditsWhileWaiting() {
        withFullService()
        
        let state = MockStateDelegate()
        serialPort.delegate = state
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        
        XCTAssertEqual(state.stateSequence, [.waitServiceSearch, .waitCharacteristicSearch, .waitInitialTxCredits, .open])
    }
    
    func testCloseSetsStateClosed() {
        withNoService()
        
        let state = MockStateDelegate()
        serialPort.delegate = state
        serialPort.open()
        serialPort.close()
        
        XCTAssertEqual(state.stateSequence.last!, .closed)
    }
    
    func testCloseUnsubscribesFifoIfOpen() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        serialPort.close()
        
        verify(peripheral, times(1)).setNotify(false, for: equal(to: fifo))
    }
    
    func testCloseUnsubscribesCreditsIfWithCredits() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        serialPort.close()
        
        verify(peripheral, times(1)).setNotify(false, for: equal(to: credits))
    }
    
    func testCloseWritesCloseValueToCreditsIfWithCredits() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        serialPort.close()
        
        verify(peripheral, times(1)).write(equal(to: Data([255])), for: equal(to: credits), type: any())
    }
    
    func testDoesNotWriteIfNotOpen() {
        serialPort.write(data: Data([0, 1, 2, 3]))
        
        verify(peripheral, never()).write(any(), for: equal(to: fifo), type: any())
    }
    
    func testWriteIfPortOpen() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        serialPort.write(data: Data([0, 1, 2, 3]))
        
        verify(peripheral, times(1)).write(equal(to: Data([0, 1, 2, 3])), for: equal(to: fifo), type: equal(to: .withoutResponse))
    }
    
    func testDoNotWriteIfUnsufficientCredits() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([0])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        serialPort.write(data: Data([0, 1, 2, 3]))
        
        verify(peripheral, never()).write(any(), for: equal(to: fifo), type: equal(to: .withoutResponse))
    }
    
    func testWritingConsumesCreditsAndOnlyWritesPerCredit() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([1])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        
        serialPort.write(data: Data([0, 1, 2, 3]))
        serialPort.write(data: Data([4, 5, 6, 7]))
        
        verify(peripheral, times(1)).write(any(), for: equal(to: fifo), type: equal(to: .withoutResponse))
    }
    
    func testWritingWithoutFlowControlIgnoresCredits() {
        withFullService()
        
        serialPort.withFlowControl = false
        serialPort.open()
        
        serialPort.write(data: Data([0, 1, 2, 3]))
        serialPort.write(data: Data([0, 1, 2, 3]))
        serialPort.write(data: Data([0, 1, 2, 3]))
        serialPort.write(data: Data([0, 1, 2, 3]))
        
        verify(peripheral, times(4)).write(equal(to: Data([0, 1, 2, 3])), for: equal(to: fifo), type: equal(to: .withoutResponse))
    }
    
    func testWritingEnqueuesDataAndSendWhenCreditsAvailable() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([0])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        serialPort.write(data: Data([0, 1, 2, 3]))
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        
        verify(peripheral, times(1)).write(equal(to: Data([0, 1, 2, 3])), for: equal(to: fifo), type: equal(to: .withoutResponse))
    }
    
    func testReceivingFifoDataConsumesRxCreditsAndResendAfterHalf() {
        withFullService()
        
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        
        fifo.value = Data([0, 1, 3, 4])
        for _ in 0..<16 {
            serialPort.processDidUpdateValueFor(fifo, error: nil)
        }
        
        verify(peripheral, times(1)).write(equal(to: Data([16])), for: equal(to: credits), type: any())
    }
    
    func testWrittenDataIsReportedBack() {
        withFullService()
        
        let callback = MockStreamDelegate()
        serialPort.setDelegate(delegate: callback)
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        
        serialPort.write(data: Data([0, 1, 2, 3]))
        serialPort.processIsReadyToSend()
        
        XCTAssertEqual(callback.lastValue, Data([0, 1, 2, 3]))
    }
    
    func testReceivedDataIsReportedBack() {
        withFullService()
        
        let callback = MockStreamDelegate()
        serialPort.setDelegate(delegate: callback)
        serialPort.open()
        credits.value = Data([32])
        serialPort.processDidUpdateValueFor(credits, error: nil)
        
        fifo.value = Data([0, 1, 2, 3])
        serialPort.processDidUpdateValueFor(fifo, error: nil)
        
        XCTAssertEqual(callback.lastValue, Data([0, 1, 2, 3]))
    }
    
    func testReceivingDataWithNoFlowDoesNotSendCredits() {
        withFullService()
        
        serialPort.withFlowControl = false
        serialPort.open()
        
        fifo.value = Data([0, 1, 2, 3])
        for _ in 0..<32 {
            serialPort.processDidUpdateValueFor(fifo, error: nil)
        }
        
        verify(peripheral, never()).write(any(), for: any(), type: any())
    }
    
    func withFullService() {
        sps.characteristics = [fifo, credits]
        stub (peripheral) { mocked in
            when(mocked.services.get).thenReturn([sps])
        }
    }
    
    func withHalfService() {
        sps.characteristics = [fifo]
        stub (peripheral) { mocked in
            when(mocked.services.get).thenReturn([sps])
        }
    }
    
    func withNoService() {
        stub (peripheral) { mocked in
            when(mocked.services.get).thenReturn([])
        }
    }
}

class MockStateDelegate : UbloxSerialPortDelegate {
    var stateSequence: [SerialPortState] = []
    
    func serialPortDidUpdateState(_ serialPort: UbloxSerialPort) {
        stateSequence.append(serialPort.state)
    }
}

class MockStreamDelegate : DataStreamDelegate {
    var lastValue: Data = Data()
    
    func dataStreamChangedState(_ stream: DataStream) {
        
    }
    
    func dataStream(_ stream: DataStream, wrote data: Data) {
        lastValue = data
    }
    
    func dataStream(_ stream: DataStream, read data: Data) {
        lastValue = data
    }
}
