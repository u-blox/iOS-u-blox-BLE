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

enum LoggerMessageType: Int {
    case quiet, normal, verbose, none
}

struct Logger {
    static var type: LoggerMessageType = .none

    static func quiet(message: String) {
        _ = print(message: message, for: .quiet)
    }

    static func normal(message: String) {
        _ = print(message: message, for: .normal)
    }

    static func verbose(message: String) {
        _ = print(message: message, for: .verbose)
    }

    static func print(message: String, for type: LoggerMessageType) -> Bool {
        guard self.type.rawValue <= type.rawValue else {
            return false
        }
        Swift.print(message)
        return true
    }
}

