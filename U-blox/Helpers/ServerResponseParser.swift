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

enum ServerResponseType {
    case help(commandName: String?)
    case scan(time: TimeInterval?)
    case stop
    case test(testSettings: TestSettings)
    case unknown
}

fileprivate enum CommandType: String {
    case tx, rx, credits, packagesize, bytecount
}

struct ServerResponseParser {
    static func parse(message: String) -> ServerResponseType {
        var messageComponents = message.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "").components(separatedBy: " ")
        guard messageComponents.count > 0 else {
            return .unknown
        }

        switch messageComponents.removeFirst() {
        case "help":
            guard let commandName = messageComponents.first else {
                return .help(commandName: nil)
            }
            return .help(commandName: commandName)
        case "scan":
            guard let scanTime = messageComponents.first else {
                return .scan(time: nil)
            }
            return .scan(time: Double(scanTime))
        case "stop":
            return .stop
        case "test":
            guard let testSettings = parse(arguments: messageComponents) else {
                return .unknown
            }
            return .test(testSettings: testSettings)
        default:
            return .unknown
        }
    }
    private static func parse(arguments: [String]) -> TestSettings? {
        var arguments = arguments
        var testSettings = TestSettings()

        guard arguments.count > 0 else {
            return nil
        }

        testSettings.deviceName = arguments.removeFirst()

        while arguments.count > 0 {
            let argument = arguments.removeFirst().components(separatedBy: "=")

            guard let command = CommandType(rawValue: argument.first!) else {
                    return nil
            }

            switch command {
            case .rx:
                testSettings.showRx = true
            case .tx:
                testSettings.showTx = true
            case .credits:
                testSettings.testingCredits = true
            case .bytecount:
                if argument.count == 2, let value = Int(argument.last!) {
                    testSettings.byteCount = value
                }
            case .packagesize:
                if argument.count == 2, let value = Int(argument.last!) {
                    testSettings.packageSize = value
                }
            }
        }
        return testSettings
    }
}
