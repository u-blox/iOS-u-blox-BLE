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

class TcpServerSocket: DataStreamListener {
    private var usePort: UInt16
    private var socket: CFSocket?
    private var socketRunLoopSource: CFRunLoopSource?
    
    weak var delegate: DataStreamListenerDelegate?
    var isListening: Bool {
        return socket != nil
    }
    private(set) var identifier: String?
    
    init(port: UInt16) {
        usePort = port
    }
    
    func startListen() {
        identifier = ipAddress
        guard identifier != nil else {
            return
        }
        initiateSocket()
        enableSocketShare()
        bindPort()
        addToRunLoop()
    }
    
    func stopListen() {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), socketRunLoopSource, .defaultMode)
        CFSocketInvalidate(socket)
        
        socketRunLoopSource = nil
        socket = nil
        identifier = nil
    }
    
    private func initiateSocket() {
        var context = self.context
        
        socket = CFSocketCreate(
            kCFAllocatorDefault,
            PF_INET,
            SOCK_STREAM,
            IPPROTO_TCP,
            CFSocketCallBackType.acceptCallBack.rawValue, socketCallback, &context)
    }
    
    private var context: CFSocketContext {
        var context = CFSocketContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        return context
    }
    
    private var ipAddress: String? {
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
    
    private func enableSocketShare() {
        var yes: Int = 1
        setsockopt(CFSocketGetNative(socket), SOL_SOCKET, SO_REUSEPORT, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
    }
    
    private func bindPort() {
        var addressStruct = sockaddr_in()
        addressStruct.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addressStruct.sin_family = sa_family_t(AF_INET)
        addressStruct.sin_port = usePort.bigEndian
        addressStruct.sin_addr.s_addr = INADDR_ANY
        
        let addressData = CFDataCreate(kCFAllocatorDefault,
                                 NSData(bytes: &addressStruct, length: MemoryLayout<sockaddr_in>.size).bytes.assumingMemoryBound(to: UInt8.self),
                                 MemoryLayout.size(ofValue: addressStruct))
        
        CFSocketSetAddress(socket, addressData)
    }
    
    private func addToRunLoop() {
        socketRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), socketRunLoopSource, .defaultMode)
    }
    
    private var socketCallback: CFSocketCallBack = { (_, callbackType, _, dataPointer, infoPointer) in
        guard callbackType == .acceptCallBack, let infoPointer = infoPointer,
            let clientSocketHandle = dataPointer?.assumingMemoryBound(to: CFSocketNativeHandle.self).pointee else {
                return
        }
        
        let this = Unmanaged<TcpServerSocket>.fromOpaque(infoPointer).takeUnretainedValue()
        this.acceptConnection(clientSocketHandle)
    }
    
    private func acceptConnection(_ clientHandle: CFSocketNativeHandle) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, clientHandle, &readStream, &writeStream);
        
        guard let inputStream: InputStream = readStream?.takeRetainedValue(),
            let outputStream: OutputStream = writeStream?.takeRetainedValue() else {
                return
        }
        
        delegate?.dataStreamListener(self, accepted: TcpStream(input: inputStream, output: outputStream))
    }
}
