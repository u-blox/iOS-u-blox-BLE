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

class TcpStream: NSObject, DataStream, StreamDelegate {
    private let inputStream: InputStream
    private let outputStream: OutputStream
    
    private(set) var streamState: DataStreamState
    weak private var delegate: DataStreamDelegate?
    
    init(input: InputStream, output: OutputStream) {
        streamState = .closed
        inputStream = input
        outputStream = output
    }
    
    func setDelegate(delegate: DataStreamDelegate) {
        self.delegate = delegate
    }
    
    func open() {
        open(stream: inputStream)
        open(stream: outputStream)
    }
    
    func close() {
        closeWith(.closed)
    }
    
    func closeWith(_ state: DataStreamState) {
        close(stream: inputStream)
        close(stream: outputStream)
        setState(state)
    }
    
    func write(data: Data) {
        var written = 0
        data.withUnsafeBytes {
            written = outputStream.write($0, maxLength: data.count)
        }
        if written > 0 {
            delegate?.dataStream(self, wrote: data)
        }
    }
    
    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if (stream == inputStream || stream == outputStream) && inputStream.streamStatus == .open && outputStream.streamStatus == .open {
                setState(.opened)
            }
        case .endEncountered:
            if stream == inputStream || stream == outputStream {
                closeWith(.closed)
            }
        case .errorOccurred:
            if stream == inputStream || stream == outputStream {
                closeWith(.error)
            }
        case .hasBytesAvailable:
            if stream == inputStream {
                readAvailable()
            }
        default: break
        }
    }
    
    private func open(stream: Stream) {
        stream.delegate = self
        stream.schedule(in: .current, forMode: .default)
        stream.open()
    }
    
    private func close(stream: Stream) {
        stream.close()
        stream.remove(from: .current, forMode: .default)
        stream.delegate = nil
    }
    
    private func readAvailable() {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let read = inputStream.read(buffer, maxLength: bufferSize)
        var data = Data()
        data.append(buffer, count: read)
        buffer.deallocate()
        if read > 0 {
            delegate?.dataStream(self, read: data)
        }
    }
    
    private func setState(_ newState: DataStreamState) {
        guard newState != streamState else {
            return
        }
        streamState = newState
        delegate?.dataStreamChangedState(self)
    }
}
