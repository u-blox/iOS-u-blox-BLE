import XCTest
@testable import U_blox

class DataPumpTests: XCTestCase {
    var pump: DataPump!
    var mockStream: MockDataStream!
    var mockDelegate: MockDataPumpDelegate!

    override func setUp() {
        mockStream = MockDataStream()
        mockDelegate = MockDataPumpDelegate()
        pump = DataPump(stream: mockStream, delegate: mockDelegate)
    }

    func testStartingWithContinuousSetsIsRunning() {
        pump.start(continuous: true)
        XCTAssertEqual(pump.isRunning, true)
    }
    
    func testStartNotContinuousDoesNotSetIsRunning() {
        pump.start(continuous: false)
        XCTAssertEqual(pump.isRunning, false)
    }
    
    func testStartingNotContinuousAfterContinuousDoesNotStopContinuous() {
        pump.start(continuous: true)
        pump.start(continuous: false)
        XCTAssertEqual(pump.isRunning, true)
    }
    
    func testStartingContinuousCallsWriteOnStream() {
        pump.start(continuous: true)
        XCTAssertGreaterThan(mockStream.writeCalls, 0)
    }
    
    func testStartingNotContinuousCallsWriteOnStream() {
        pump.start(continuous: false)
        XCTAssertGreaterThan(mockStream.writeCalls, 0)
    }
    
    func testStop() {
        pump.start(continuous: true)
        pump.stop()
        XCTAssertEqual(pump.isRunning, false)
    }
    
    func testStopStopsTheStopWatch() {
        pump.start(continuous: true)
        pump.stop()
        mockStream.delegate?.onWrite(data: Data())
        let firstTime = mockDelegate.lastReportedDuration
        mockStream.delegate?.onWrite(data: Data())
        XCTAssertEqual(firstTime, mockDelegate.lastReportedDuration)
    }
    
    func testStartingAfterStoppingResetsTxCounter() {
        pump.start(continuous: true)
        mockStream.delegate?.onWrite(data: Data([0]))
        pump.stop()
        pump.start(continuous: true)
        mockStream.delegate?.onWrite(data: Data([0]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 1)
    }
    
    func testResetRxResetsReceivedByteCounter() {
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3]))
        pump.resetRx()
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 4)
    }
    
    func testResetStopsTheStopWatch() {
        mockStream.delegate?.onRead(data: Data())
        mockStream.delegate?.onRead(data: Data())
        mockStream.delegate?.onRead(data: Data())
        let timeBefore = mockDelegate.lastReportedDuration
        pump.resetRx()
        mockStream.delegate?.onRead(data: Data())
        XCTAssertLessThan(mockDelegate.lastReportedDuration, timeBefore)
    }
    
    func testSendMoreIfContinuous() {
        pump.start(continuous: true)
        mockStream.delegate?.onWrite(data: Data())
        XCTAssertEqual(mockStream.writeCalls, 2)
    }
    
    func testDoNotSendMoreIfNotContinuous() {
        pump.start(continuous: false)
        mockStream.delegate?.onWrite(data: Data())
        XCTAssertEqual(mockStream.writeCalls, 1)
    }
    
    func testCorrectlyKeepsTrackOfSentBytes() {
        mockStream.delegate?.onWrite(data: Data([0, 1, 2, 3]))
        mockStream.delegate?.onWrite(data: Data([0, 1, 2, 3]))
        mockStream.delegate?.onWrite(data: Data([0, 1, 2, 3]))
        mockStream.delegate?.onWrite(data: Data([0, 1, 2, 3]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 16)
    }
    
    func testCorrectlyKeepTrackOfReceivedBytes() {
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3, 4, 5, 6, 7]))
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3, 4, 5, 6, 7]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 16)
    }
    
    func testStartingContinuousStartsStopWatch() {
        pump.start(continuous: true)
        mockStream.delegate?.onWrite(data: Data())
        XCTAssertGreaterThan(mockDelegate.lastReportedDuration, 0)
    }
    
    func testStartingNotContinuousStartsStopWatch() {
        pump.start(continuous: false)
        mockStream.delegate?.onWrite(data: Data())
        XCTAssertGreaterThan(mockDelegate.lastReportedDuration, 0)
    }
    
    func testReceivingDataStartsStopWatch() {
        mockStream.delegate?.onRead(data: Data())
        XCTAssertGreaterThan(mockDelegate.lastReportedDuration, 0)
    }
    
    func testPacketVar() {
        XCTAssertEqual(pump.packet, Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]))
    }
    
    func testNoErrorSinglePacket() {
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3]))
        XCTAssertEqual(mockDelegate.errorCount, 0)
    }
    
    func testNoErrorOverMorePackets() {
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3]))
        mockStream.delegate?.onRead(data: Data([4, 5, 0, 1]))
        XCTAssertEqual(mockDelegate.errorCount, 0)
    }
    
    func testErrorSinglePacket() {
        mockStream.delegate?.onRead(data: Data([0, 1, 3, 3]))
        XCTAssertEqual(mockDelegate.errorCount, 2)
    }
    
    func testErrorOverMorePackets() {
        mockStream.delegate?.onRead(data: Data([0, 1, 2, 3]))
        mockStream.delegate?.onRead(data: Data([8, 9, 10, 11]))
        XCTAssertEqual(mockDelegate.errorCount, 1)
    }
    
    func testErrorCountResetsOnResetRx() {
        mockStream.delegate?.onRead(data: Data([0, 1, 3, 4]))
        pump.resetRx()
        mockStream.delegate?.onRead(data: Data([0, 1, 3, 4]))
        XCTAssertEqual(mockDelegate.errorCount, 1)
    }
}

class MockDataStream : DataStream {
    var delegate: DataStreamDelegate?
    var writeCalls: Int
    
    init() {
        delegate = nil
        writeCalls = 0
    }
    
    func setDelegate(delegate: DataStreamDelegate) {
        self.delegate = delegate
    }
    
    func write(data: Data) {
        writeCalls += 1
    }
}

class MockDataPumpDelegate : DataPumpDelegate {
    var lastReportedBytes: UInt64
    var lastReportedDuration: UInt64
    var errorCount: UInt32
    
    init() {
        lastReportedBytes = 0
        lastReportedDuration = 0
        errorCount = 0
    }
    
    func onTx(bytes: UInt64, duration: UInt64) {
        lastReportedBytes = bytes
        lastReportedDuration = duration
    }
    
    func onRx(bytes: UInt64, duration: UInt64) {
        lastReportedBytes = bytes
        lastReportedDuration = duration
    }
    
    func onRxError(errorCount: UInt32) {
        self.errorCount = errorCount
    }
}
