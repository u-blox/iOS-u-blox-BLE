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
import UIKit

struct TestSettings {
    var showTx = false
    var showRx = false
    var testingCredits = false
    var packageSize = 20
    var byteCount: Int?
    var deviceName: String?
}

typealias ServerMessageReceived = (ServerResponseType) -> ()
class Server: NSObject {

    var serverMessageReceived: ServerMessageReceived?

    private(set) var isTesting = false
    private(set) var isOn = false
    private(set) var testStartTime: Date?

    fileprivate var native: CFSocketNativeHandle = 0

    private var readStream: Unmanaged<CFReadStream>?
    private var writeStream: Unmanaged<CFWriteStream>?

    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var runLoopSocketSource: CFRunLoopSource?
    private var socket: CFSocket?

    var handleConnection : CFSocketCallBack = { (_,callBackType,_,pointer,mutablePointer) in

        guard callBackType == .acceptCallBack, let mutablePointer = mutablePointer,
            let native = pointer?.assumingMemoryBound(to: CFSocketNativeHandle.self).pointee else {
                return
        }

        let svc = Unmanaged<Server>.fromOpaque(mutablePointer).takeUnretainedValue()
        svc.native = native
        svc.handleCallback()
    }

    var ipAddress: String? {
        var address : String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {

            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr?.pointee

                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: interface!.ifa_name)
                    if name == "en0" {

                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface!.ifa_addr, socklen_t(interface!.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address

    }

    init(serverMessageReceived: ServerMessageReceived? = nil) {
        self.serverMessageReceived = serverMessageReceived
    }

    func start(on port: UInt16 = 55123) {

        var context = CFSocketContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let myipv4cfsock = CFSocketCreate(
            kCFAllocatorDefault,
            PF_INET,
            SOCK_STREAM,
            IPPROTO_TCP,
            CFSocketCallBackType.acceptCallBack.rawValue, handleConnection, &context)

        var yes: Int = 1
        setsockopt(CFSocketGetNative(myipv4cfsock), SOL_SOCKET, SO_REUSEPORT, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
        var sin4 = sockaddr_in()
        sin4.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        sin4.sin_family = sa_family_t(AF_INET)
        sin4.sin_port = port.bigEndian
        sin4.sin_addr.s_addr = INADDR_ANY

        let data4 = CFDataCreate(kCFAllocatorDefault,
                                 NSData(bytes: &sin4, length: MemoryLayout<sockaddr_in>.size).bytes.assumingMemoryBound(to: UInt8.self),
                                 MemoryLayout.size(ofValue: sin4))
        CFSocketSetAddress(myipv4cfsock, data4)
        socket = myipv4cfsock
        let socketSource4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, myipv4cfsock, 0)
        runLoopSocketSource = socketSource4
        CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSource4, .defaultMode)

        isOn = true
    }

    func stop() {
        inputStream?.close()
        outputStream?.close()

        inputStream?.remove(from: .current, forMode: .defaultRunLoopMode)
        outputStream?.remove(from: .current, forMode: .defaultRunLoopMode)

        inputStream?.delegate = nil
        outputStream?.delegate = nil

        inputStream = nil
        outputStream = nil

        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSocketSource, .defaultMode)
        CFSocketInvalidate(socket)

        runLoopSocketSource = nil
        socket = nil
        isOn = false
    }
    fileprivate func handleCallback() {
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, native, &readStream, &writeStream);

        inputStream = readStream?.takeRetainedValue()
        outputStream = writeStream?.takeRetainedValue()

        inputStream?.delegate = self
        outputStream?.delegate = self

        inputStream?.schedule(in: .current, forMode: .defaultRunLoopMode)
        outputStream?.schedule(in: .current, forMode: .defaultRunLoopMode)

        inputStream?.open()
        outputStream?.open()
    }
    func write(message: String) {
        let data = "\(message)\r\n".data(using: .utf8)!
        _ = data.withUnsafeBytes { outputStream?.write($0, maxLength: data.count) }
        Logger.normal(message: "Writing out the following: \(message)")
    }
}
extension Server: StreamDelegate {

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        Logger.normal(message: "Stream triggered.")

        switch eventCode {
        case .hasBytesAvailable:
            if aStream == inputStream {
                let buffer = UnsafeMutablePointer<Byte>.allocate(capacity: 1024)
                guard let count = inputStream?.read(&buffer.pointee, maxLength: 1024),
                    count > 0 else {
                        return
                }
                var data = Data()
                data.append(buffer, count: count)
                let message = String(data: data, encoding: .utf8)!
                Logger.normal(message: "Server received message: \(message)")
                serverMessageReceived?(ServerResponseParser.parse(message: message))
            }
        default:
            Logger.normal(message: "Stream is sending an Event: \(eventCode)")
        }
    }
}

