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

class DataPump : DataStreamDelegate {
    private var bytesTx: UInt64
    private var timeTx: StopWatch
    private var bytesRx: UInt64
    private var timeRx: StopWatch
    private var errorCount: UInt32
    private var lastByte: UInt8
    private var continuous: Bool
    private let stream: DataStream
    private let delegate: DataPumpDelegate
    var packetSize: Int
    
    init(stream: DataStream, delegate: DataPumpDelegate) {
        bytesTx = 0
        timeTx = StopWatch()
        bytesRx = 0
        timeRx = StopWatch()
        errorCount = 0
        lastByte = 0
        continuous = false
        packetSize = 20
        self.stream = stream
        self.delegate = delegate
        stream.setDelegate(delegate: self)
    }
    
    var isRunning: Bool {
        return continuous
    }
    
    func start(continuous: Bool) {
        timeTx.start()
        guard !self.continuous else {
            return
        }
        bytesTx = 0
        self.continuous = continuous
        stream.write(data: packet)
    }
    
    func stop() {
        continuous = false
    }
    
    func resetRx() {
        bytesRx = 0
        errorCount = 0
        timeRx.stop()
    }
    
    func resetTx() { // Todo: Figure out if this is really needed if we reset on restarting datapump
        bytesTx = 0
        timeTx.stop()
        timeTx.start()
    }
    
    func onWrite(data: Data) {
        if !continuous {
            timeTx.stop()
        }
        let time = timeTx.elapsedTime
        bytesTx += UInt64(data.count)
        delegate.onTx(bytes: bytesTx, duration: time)
        if continuous {
            stream.write(data: packet)
        }
    }
    
    func onRead(data: Data) {
        timeRx.start()
        let time = timeRx.elapsedTime
        bytesRx += UInt64(data.count)
        delegate.onRx(bytes: bytesRx, duration: time)
        errorCheck(data: data)
    }
    
    func errorCheck(data: Data) {
        var errors: UInt32 = 0
        for byte in data {
            if byte != 0 && byte != lastByte + 1 {
                errors += 1
            }
            lastByte = byte
        }
        guard errors > 0 else {
            return
        }
        errorCount += errors
        delegate.onRxError(errorCount: errorCount)
    }
    
    var packet: Data {
        var data = Data()
        for i in 0..<packetSize {
            data.append(UInt8(i % 256))
        }
        return data
    }
}

protocol DataPumpDelegate{
    func onTx(bytes: UInt64, duration: UInt64)
    func onRx(bytes: UInt64, duration: UInt64)
    func onRxError(errorCount: UInt32)
}
