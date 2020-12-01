import Foundation
import CoreBluetooth
import XCTest
import Cuckoo
@testable import U_blox

class TestSpsStream: XCTestCase {
    
    func testOpenCallsConnect() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        
        verify(mock, times(1)).connect()
    }
    
    func testWhenConnectedStartDiscovery() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        
        verify(mock, times(1)).discover(services: equal(to: [SpsStream.serialPortService]))
    }
    
    func testWhenSpsCharacteristicsPresentNotifyCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        
        verify(mock, times(1)).set(characteristic: equal(to: SpsStream.creditsCharacteristic), notify: true)
    }
    
    func testWhenCreditsNotifyingNotifyFifo() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        
        verify(mock, times(1)).set(characteristic: equal(to: SpsStream.fifoCharacteristic), notify: true)
    }
    
    func testWhenNotifyingFifoSendCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        
        verify(mock, times(1)).write(characteristic: equal(to: SpsStream.creditsCharacteristic), data: equal(to: Data([32])), withResponse: any())
    }
    
    func testWhenReceivingCreditsSetStateOpen() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        
        XCTAssertEqual(stream.streamState, .opened)
    }
    
    func testDoNotOpenIfOpened() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        stream.open()
        
        verify(mock, times(1)).connect()
    }
    
    func testDoNotCloseIfNotOpened() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.close()
        
        verify(mock, never()).disconnect()
    }
    
    func testDisconnectOnClose() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        stream.close()
        
        verify(mock, times(1)).disconnect()
    }
    
    func testOpenWithoutFlowControlDoesNotNotifyCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open(withFlowControl: false)
        
        verify(mock, never()).set(characteristic: equal(to: SpsStream.creditsCharacteristic), notify: true)
        verify(mock, times(1)).set(characteristic: equal(to: SpsStream.fifoCharacteristic), notify: true)
    }
    
    func testOpenWithoutFlowControlDoesNotSendNegotiateCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open(withFlowControl: false)
        
        verify(mock, never()).write(characteristic: equal(to: SpsStream.creditsCharacteristic), data: any(), withResponse: any())
    }
    
    func testOpenWithoutFlowControlSetStateOpen() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open(withFlowControl: false)
        
        XCTAssertEqual(stream.streamState, .opened)
    }
    
    func testWriteData() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        stream.write(data: Data([0, 1, 2, 3]))
        
        verify(mock, times(1)).write(characteristic: equal(to: SpsStream.fifoCharacteristic), data: equal(to: Data([0, 1, 2, 3])), withResponse: false)
    }
    
    func testWritingMoreDataThanCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        for _ in 0..<33 {
            stream.write(data: Data())
        }
        verify(mock, times(32)).write(characteristic: equal(to: SpsStream.fifoCharacteristic), data: any(), withResponse: any())
    }
    
    func testWritingContinuesWhenReceivingMoreCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        for _ in 0..<33 {
            stream.write(data: Data())
        }
        stream.bluetoothPeripheral(mock, read: SpsStream.creditsCharacteristic, data: Data([16]), ok: true)
        verify(mock, times(33)).write(characteristic: equal(to: SpsStream.fifoCharacteristic), data: any(), withResponse: any())
    }
    
    func testDoNotWaitOnCreditsWhenNoFlowControl() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open(withFlowControl: false)
        for _ in 0..<64 {
            stream.write(data: Data())
        }
        
        verify(mock, times(64)).write(characteristic: equal(to: SpsStream.fifoCharacteristic), data: any(), withResponse: any())
    }
    
    func testSendMoreCreditsWhenHalfSpendByPeripheral() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        for _ in 0..<16 {
            stream.bluetoothPeripheral(mock, read: SpsStream.fifoCharacteristic, data: Data(), ok: true)
        }
        verify(mock, times(1)).write(characteristic: equal(to: SpsStream.creditsCharacteristic), data: equal(to: Data([16])), withResponse: false)
    }
    
    func testDoNotSendCreditsWhenNoFlowControl() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open(withFlowControl: false)
        for _ in 0..<32 {
            stream.bluetoothPeripheral(mock, read: SpsStream.fifoCharacteristic, data: Data(), ok: true)
        }
        verify(mock, never()).write(characteristic: equal(to: SpsStream.creditsCharacteristic), data: any(), withResponse: any())
    }
    
    func testReportWrittenData() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        let verifyMock = setupVerifyMock()
        stream.delegate = verifyMock
        stream.open()
        stream.write(data: Data([0, 1, 2, 3]))
        
        stream.bluetoothPeripheralReadyToWrite(mock, ok: true)
        
        verify(verifyMock, times(1)).dataStream(any(), wrote: equal(to: Data([0, 1, 2, 3])))
    }
    
    func testReportReadData() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        let verifyMock = setupVerifyMock()
        stream.delegate = verifyMock
        stream.open()
        
        stream.bluetoothPeripheral(mock, read: SpsStream.fifoCharacteristic, data: Data([0, 1, 2, 3]), ok: true)
        
        verify(verifyMock, times(1)).dataStream(any(), read: equal(to: Data([0, 1, 2, 3])))
    }
    
    func testDoNotNegotiateWhenDiscoverIfAlreadyOpen() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        stream.bluetoothPeripheralDiscovered(mock, ok: true)
        
        verify(mock, times(1)).set(characteristic: equal(to: SpsStream.creditsCharacteristic), notify: true)
    }
    
    func testDisconnectWhenReceivingClosingCredits() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        stream.open()
        stream.bluetoothPeripheral(mock, read: SpsStream.creditsCharacteristic, data: Data([255]), ok: true)
        
        XCTAssertEqual(stream.streamState, .closed)
    }
    
    func testReportZeroBytesWrittenWhenError() {
        let mock = setupFullMock()
        let verifyMock = setupVerifyMock()
        let stream = SpsStream(mock)
        stream.delegate = verifyMock
        stream.open()
        stream.write(data: Data([0, 1, 2, 3]))
        
        stream.bluetoothPeripheralReadyToWrite(mock, ok: false)
        
        verify(verifyMock, never()).dataStream(any(), wrote: equal(to: Data([0, 1, 2, 3])))
        verify(verifyMock, times(1)).dataStream(any(), wrote: equal(to: Data()))
    }
    
    func testStateErrorWhenError() {
        let mock = MockBluetoothPeripheral()
        stub(mock) {mocked in
            when(mocked.delegate.set(any())).thenDoNothing()
        }
        let stream = SpsStream(mock)
        stub(mock) {mocked in
            when(mocked.connect()).then {
                stream.bluetoothPeripheralChangedState(mock)
            }
            when(mocked.identifier.get).thenReturn(UUID(uuid: UUID_NULL))
            when(mocked.state.get).thenReturn(.error)
        }
        stream.open()
        
        XCTAssertEqual(stream.streamState, .error)
    }
    
    func testWhenNoSerialPortServiceReportError() {
        let mock = MockBluetoothPeripheral()
        stub(mock) { mocked in
            when(mocked.identifier.get).thenReturn(UUID(uuid: UUID_NULL))
            when(mocked.delegate.set(any())).then() { (delegate) in
                stub(mock) { mocked in
                    when(mocked.state.get).thenReturn(.connected, .disconnected)
                    when(mocked.connect()).then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked.disconnect()).then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked.discover(services: any())).then() { _ in
                        delegate?.bluetoothPeripheralDiscovered(mock, ok: true)
                    }
                    when(mocked.characteristics(service: any())).thenReturn([])
                }
            }
        }
        let stream = SpsStream(mock)
        stream.open()
        
        XCTAssertEqual(stream.streamState, .error)
    }
    
    func testErrorWhenFailedToNotifyCredits() {
        let mock = MockBluetoothPeripheral()
        stub (mock) { mocked in
            when(mocked.identifier.get).thenReturn(UUID(uuid: UUID_NULL))
            when(mocked.delegate.set(any())).then { (delegate) in
                stub (mock) {mocked in
                    when(mocked.state.get).thenReturn(.connected, .disconnected)
                    when(mocked.connect()).then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked).disconnect().then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked.discover(services: any())).then { _ in
                        delegate?.bluetoothPeripheralDiscovered(mock, ok: true)
                    }
                    when(mocked.services()).thenReturn([SpsStream.serialPortService])
                    when(mocked.characteristics(service: equal(to: SpsStream.serialPortService))).thenReturn([SpsStream.creditsCharacteristic, SpsStream.fifoCharacteristic])
                    when(mocked.set(characteristic: any(), notify: any())).then { (uuid, notify) in
                        delegate?.bluetoothPeripheral(mock, set: uuid, notify: false, ok: false)
                    }
                }
            }
        }
        
        let stream = SpsStream(mock)
        stream.open()
        
        XCTAssertEqual(stream.streamState, .error)
    }
    
    func testErrorWhenFailedToNotifyFifo() {
        let mock = MockBluetoothPeripheral()
        stub (mock) { mocked in
            when(mocked.identifier.get).thenReturn(UUID(uuid: UUID_NULL))
            when(mocked.delegate.set(any())).then { (delegate) in
                stub (mock) {mocked in
                    when(mocked.state.get).thenReturn(.connected, .disconnected)
                    when(mocked.connect()).then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked).disconnect().then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked.discover(services: any())).then { _ in
                        delegate?.bluetoothPeripheralDiscovered(mock, ok: true)
                    }
                    when(mocked.services()).thenReturn([SpsStream.serialPortService])
                    when(mocked.characteristics(service: equal(to: SpsStream.serialPortService))).thenReturn([SpsStream.creditsCharacteristic, SpsStream.fifoCharacteristic])
                    when(mocked.set(characteristic: any(), notify: any())).then { (uuid, notify) in
                        delegate?.bluetoothPeripheral(mock, set: uuid, notify: false, ok: false)
                    }
                }
            }
        }
        
        let stream = SpsStream(mock)
        stream.open(withFlowControl: false)
        
        XCTAssertEqual(stream.streamState, .error)
    }
    
    func testDelegateCalledWhenOpened() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        let verifyMock = setupVerifyMock()
        stream.delegate = verifyMock
        stream.open()
        
        verify(verifyMock, times(1)).dataStreamChangedState(any())
    }
    
    func testDelegateCalledWhenClosed() {
        let mock = setupFullMock()
        let stream = SpsStream(mock)
        let verifyMock = setupVerifyMock()
        stream.open()
        stream.delegate = verifyMock
        stream.close()
        
        verify(verifyMock, times(1)).dataStreamChangedState(any())
    }
    
    func setupFullMock() -> MockBluetoothPeripheral {
        let mock = MockBluetoothPeripheral()
        stub (mock) { mocked in
            when(mocked.identifier.get).thenReturn(UUID(uuid: UUID_NULL))
            when(mocked.delegate.set(any())).then { (delegate) in
                stub (mock) {mocked in
                    when(mocked.state.get).thenReturn(.connected, .disconnected)
                    when(mocked.connect()).then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked).disconnect().then {
                        delegate?.bluetoothPeripheralChangedState(mock)
                    }
                    when(mocked.discover(services: any())).then { _ in
                        delegate?.bluetoothPeripheralDiscovered(mock, ok: true)
                    }
                    when(mocked.services()).thenReturn([SpsStream.serialPortService])
                    when(mocked.characteristics(service: equal(to: SpsStream.serialPortService))).thenReturn([SpsStream.creditsCharacteristic, SpsStream.fifoCharacteristic])
                    when(mocked.set(characteristic: any(), notify: any())).then { (uuid, notify) in
                        delegate?.bluetoothPeripheral(mock, set: uuid, notify: notify, ok: true)
                    }
                    when(mocked.write(characteristic: any(), data: any(), withResponse: any())).thenDoNothing()
                    when(mocked.write(characteristic: equal(to: SpsStream.creditsCharacteristic), data: equal(to: Data([32])), withResponse: any())).then { (uuid, data, response) in
                        delegate?.bluetoothPeripheral(mock, read: uuid, data: data, ok: true)
                    }
                }
            }
        }
        return mock
    }
    
    func setupVerifyMock() -> MockDataStreamDelegate {
        let mock = MockDataStreamDelegate()
        stub (mock) { mocked in
            when(mocked.dataStreamChangedState(any())).thenDoNothing()
            when(mocked.dataStream(any(), read: any())).thenDoNothing()
            when(mocked.dataStream(any(), wrote: any())).thenDoNothing()
        }
        return mock
    }
}
