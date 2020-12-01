import XCTest
@testable import U_blox

class DataPumpTests: XCTestCase {
    var pump: DataPump!
    var mockStream: StubDataStream!
    var mockDelegate: MockDataPumpDelegate!

    override func setUp() {
        mockStream = StubDataStream()
        mockDelegate = MockDataPumpDelegate()
        pump = DataPump(stream: mockStream)
        pump.delegate = mockDelegate
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
        mockStream.delegate?.dataStream(mockStream, wrote: Data())
        let firstTime = mockDelegate.lastReportedDuration
        mockStream.delegate?.dataStream(mockStream, wrote: Data())
        XCTAssertEqual(firstTime, mockDelegate.lastReportedDuration)
    }
    
    func testStartingAfterStoppingResetsTxCounter() {
        pump.start(continuous: true)
        mockStream.delegate?.dataStream(mockStream, wrote: Data([0]))
        pump.stop()
        pump.start(continuous: true)
        mockStream.delegate?.dataStream(mockStream, wrote: Data([0]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 1)
    }
    
    func testResetRxResetsReceivedByteCounter() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3]))
        pump.resetRx()
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 4)
    }
    
    func testResetStopsTheStopWatch() {
        mockStream.delegate?.dataStream(mockStream, read: Data())
        mockStream.delegate?.dataStream(mockStream, read: Data())
        mockStream.delegate?.dataStream(mockStream, read: Data())
        let timeBefore = mockDelegate.lastReportedDuration
        pump.resetRx()
        mockStream.delegate?.dataStream(mockStream, read: Data())
        XCTAssertLessThan(mockDelegate.lastReportedDuration, timeBefore)
    }
    
    func testSendMoreIfContinuous() {
        pump.start(continuous: true)
        mockStream.delegate?.dataStream(mockStream, wrote: Data())
        XCTAssertEqual(mockStream.writeCalls, 2)
    }
    
    func testDoNotSendMoreIfNotContinuous() {
        pump.start(continuous: false)
        mockStream.delegate?.dataStream(mockStream, wrote: Data())
        XCTAssertEqual(mockStream.writeCalls, 1)
    }
    
    func testCorrectlyKeepsTrackOfSentBytes() {
        mockStream.delegate?.dataStream(mockStream, wrote: Data([0, 1, 2, 3]))
        mockStream.delegate?.dataStream(mockStream, wrote: Data([0, 1, 2, 3]))
        mockStream.delegate?.dataStream(mockStream, wrote: Data([0, 1, 2, 3]))
        mockStream.delegate?.dataStream(mockStream, wrote: Data([0, 1, 2, 3]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 16)
    }
    
    func testCorrectlyKeepTrackOfReceivedBytes() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3, 4, 5, 6, 7]))
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3, 4, 5, 6, 7]))
        XCTAssertEqual(mockDelegate.lastReportedBytes, 16)
    }
    
    func testStartingContinuousStartsStopWatch() {
        pump.start(continuous: true)
        mockStream.delegate?.dataStream(mockStream, wrote: Data())
        XCTAssertGreaterThan(mockDelegate.lastReportedDuration, 0)
    }
    
    func testStartingNotContinuousStartsStopWatch() {
        pump.start(continuous: false)
        mockStream.delegate?.dataStream(mockStream, wrote: Data())
        XCTAssertGreaterThan(mockDelegate.lastReportedDuration, 0)
    }
    
    func testReceivingDataStartsStopWatch() {
        mockStream.delegate?.dataStream(mockStream, read: Data())
        XCTAssertGreaterThan(mockDelegate.lastReportedDuration, 0)
    }
    
    func testPacketVar() {
        XCTAssertEqual(pump.packet, Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]))
    }
    
    func testNoErrorSinglePacket() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3]))
        XCTAssertEqual(mockDelegate.errorCount, 0)
    }
    
    func testNoErrorOverMorePackets() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3]))
        mockStream.delegate?.dataStream(mockStream, read: Data([4, 5, 0, 1]))
        XCTAssertEqual(mockDelegate.errorCount, 0)
    }
    
    func testErrorSinglePacket() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 3, 3]))
        XCTAssertEqual(mockDelegate.errorCount, 1)
    }
    
    func testErrorOverMorePackets() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 2, 3]))
        mockStream.delegate?.dataStream(mockStream, read: Data([3, 5, 6, 7]))
        XCTAssertEqual(mockDelegate.errorCount, 1)
    }
    
    func testErrorCountResetsOnResetRx() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 3, 3]))
        pump.resetRx()
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 3, 3]))
        XCTAssertEqual(mockDelegate.errorCount, 1)
    }
    
    func testReceivingZeroIsNotError() {
        mockStream.delegate?.dataStream(mockStream, read: Data([0, 1, 0, 1]))
        XCTAssertEqual(mockDelegate.errorCount, 0)
    }
    
    func testNoErrorOnCompleteMaxLengthPackets() {
        var packet = Data()
        for i in 0..<256 {
            packet.append(UInt8(i))
        }
        mockStream.delegate?.dataStream(mockStream, read: packet)
        mockStream.delegate?.dataStream(mockStream, read: packet)
        XCTAssertEqual(mockDelegate.errorCount, 0)
    }
}

class StubDataStream : DataStream {
    var streamState: DataStreamState = .opened
    
    var delegate: DataStreamDelegate?
    var writeCalls: Int
    
    init() {
        delegate = nil
        writeCalls = 0
    }
    
    func open() {}
    func close() {}
    
    func setDelegate(delegate: DataStreamDelegate) {
        self.delegate = delegate
    }
    
    func write(data: Data) {
        writeCalls += 1
    }
}

class MockDataPumpDelegate : DataPumpDelegate {
    func dataPumpStreamChangedState(_ pump: DataPump, stream: DataStream) {
        
    }
    
    var lastReportedBytes: UInt64
    var lastReportedDuration: UInt64
    var errorCount: UInt32
    
    init() {
        lastReportedBytes = 0
        lastReportedDuration = 0
        errorCount = 0
    }
    
    func dataPumpTransmitted(_ pump: DataPump, bytes: UInt64, duration: UInt64) {
        lastReportedBytes = bytes
        lastReportedDuration = duration
    }
    
    func dataPumpReceived(_ pump: DataPump, bytes: UInt64, duration: UInt64) {
        lastReportedBytes = bytes
        lastReportedDuration = duration
    }
    
    func dataPumpErrors(_ pump: DataPump, errorCount: UInt32) {
        self.errorCount = errorCount
    }
}
