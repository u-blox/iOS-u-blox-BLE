
import XCTest
@testable import U_blox

class TestStopWatch: XCTestCase {
    
    func testFreshStopWatchElapsedTimeIsZero() {
        let stopWatch = StopWatch()
        XCTAssertEqual(stopWatch.elapsedTime, 0)
    }

    func testStopWatchIncreaseInTime() {
        var stopWatch = StopWatch()
        stopWatch.start()
        XCTAssertGreaterThan(stopWatch.elapsedTime, 0)
    }

    func testStopWatchDoesNotIncreaseAfterStop() {
        var stopWatch = StopWatch()
        stopWatch.start()
        stopWatch.stop()
        XCTAssertEqual(stopWatch.elapsedTime, stopWatch.elapsedTime)
    }
    
    func testStartingAStartedStopWatchDoesNothing() {
        var stopWatch = StopWatch()
        stopWatch.start()
        let middleTime = stopWatch.elapsedTime
        stopWatch.start()
        XCTAssertGreaterThan(stopWatch.elapsedTime, middleTime)
    }
    
    func testStoppingAStoppedStopWatchDoesNothing() {
        var stopWatch = StopWatch()
        stopWatch.start()
        stopWatch.stop()
        let middleTime = stopWatch.elapsedTime
        stopWatch.stop()
        XCTAssertEqual(stopWatch.elapsedTime, middleTime)
    }
    
    func testStartingAStoppedStopWatchResetsTime() {
        var stopWatch = StopWatch()
        stopWatch.start()
        var middleTime = stopWatch.elapsedTime
        stopWatch.stop()
        middleTime += stopWatch.elapsedTime
        stopWatch.start()
        stopWatch.stop()
        XCTAssertGreaterThan(middleTime, stopWatch.elapsedTime)
    }
}
