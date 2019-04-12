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
import Dispatch

struct StopWatch {
    private var startTime: UInt64
    private var stopTime: UInt64
    private var isRunning: Bool
    
    init() {
        startTime = 0
        stopTime = 0
        isRunning = false
    }
    
    mutating func start() {
        guard !isRunning else {
            return
        }
        startTime = now
        isRunning = true
    }
    
    mutating func stop() {
        guard isRunning else {
            return
        }
        stopTime = now
        isRunning = false
    }
    
    var elapsedTime: UInt64 {
        get {
            return (isRunning ? now : stopTime) - startTime
        }
    }
    
    private var now: UInt64 {
        get {
            return DispatchTime.now().uptimeNanoseconds
        }
    }
}
