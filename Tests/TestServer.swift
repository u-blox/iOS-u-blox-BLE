import Foundation
import XCTest
import CoreBluetooth
import Cuckoo

@testable import U_blox

class TestServer: XCTestCase {
    func  testServerStarted() {
        let mockCentral = MockBluetoothCentral()
        let mockSocket = setupSocketMock()
        let server = Server(manager: mockCentral)
        server.startWith(listener: mockSocket)
        XCTAssertEqual(server.state, .running)
    }
    
    func testReplyToHelp() {
        let mockSocket = setupSocketMock()
        let mockTcp = setupTcpMock()
        let mockCentral = MockBluetoothCentral()
        let server = Server(manager: mockCentral)
        server.startWith(listener: mockSocket)
        server.dataStreamListener(mockSocket, accepted: mockTcp)
        server.dataStream(mockTcp, read: toData("help"))
        
        verify(mockTcp, atLeastOnce()).write(data: equal(to: toData("Supported commands:\r\n")))
    }
    
    func testReplyToHelpWithParameter() {
        let mockSocket = setupSocketMock()
        let mockTcp = setupTcpMock()
        let mockCentral = MockBluetoothCentral()
        let server = Server(manager: mockCentral)
        server.startWith(listener: mockSocket)
        server.dataStreamListener(mockSocket, accepted: mockTcp)
        server.dataStream(mockTcp, read: toData("help scan"))
        
        verify(mockTcp, atLeastOnce()).write(data: equal(to: toData("This command scans area for specified time and shows all visible peripherals.\r\n")))
    }
    
    func testScan() {
        let expectation = self.expectation(description: "Device name written")
        let mockSocket = setupSocketMock()
        let mockTcp = setupTcpMock()
        stub(mockTcp) {mocked in
            when(mocked.write(data: equal(to: toData("0. TEST-T0-012345\r\n")))).then{_ in
                expectation.fulfill()
            }
        }
        let mockPeripheral = MockBluetoothPeripheral()
        stub(mockPeripheral) {mocked in
            when(mocked.name.get).thenReturn("TEST-T0-012345")
        }
        let mockCentral = MockBluetoothCentral()
        stub(mockCentral) {mocked in
            when(mocked.state.get).thenReturn(.on)
            when(mocked.delegate.set(any())).thenDoNothing()
            when(mocked.scan(withServices: any())).thenDoNothing()
            when(mocked.stop()).thenDoNothing()
            when(mocked.foundDevices.get).thenReturn([mockPeripheral])
        }
        let server = Server(manager: mockCentral)
        server.startWith(listener: mockSocket)
        server.dataStreamListener(mockSocket, accepted: mockTcp)
        server.dataStream(mockTcp, read: toData("scan"))
        
        waitForExpectations(timeout: 7, handler: nil)
        //verify(mockTcp, atLeastOnce()).write(data: equal(to: "0. TEST-T0-012345\r\n".data(using: .utf8)!))
    }
    
    func toData(_ str: String?) -> Data {
        if let str = str {
            return str.data(using: .utf8)!
        } else {
            return Data()
        }
    }
    
    func setupSocketMock() -> MockDataStreamListener {
        let mockSocket = MockDataStreamListener()
        stub(mockSocket) {mocked in
            when(mocked.delegate.set(any())).thenDoNothing()
            when(mocked.startListen()).thenDoNothing()
            when(mocked.isListening.get).thenReturn(true)
        }
        return mockSocket
    }
    
    func setupTcpMock() -> MockDataStream {
        let mockTcp = MockDataStream()
        stub(mockTcp) {mocked in
            when(mocked.setDelegate(delegate: any())).thenDoNothing()
            when(mocked.open()).thenDoNothing()
            when(mocked.write(data: any())).thenDoNothing()
        }
        return mockTcp
    }
}
