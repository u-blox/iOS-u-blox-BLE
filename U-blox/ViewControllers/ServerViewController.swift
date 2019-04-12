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

import UIKit

class ServerViewController: BaseViewController {
    
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var loggingTextView: UITextView!
    
    @IBAction func startStopButtonPressed(_ sender: Any) {
        switch server.isOn {
        case true:
            log(message: "Server stop")
            startStopButton.setTitle("Start", for: .normal)
            server.stop()
        case false:
            log(message: "Server start")
            startStopButton.setTitle("Stop", for: .normal)
            if let ipAddress = server.ipAddress {
                self.log(message: "IP ADDRESS: \(ipAddress)")
            }
            server.start(on: (UInt16(portTextField.text!) ?? 55123))
        }
    }
    
    var dataPump: DataPump?
    var lastTxCount: UInt64 = 0
    var lastTxDuration: UInt64 = 0
    var lastRxCount: UInt64 = 0
    var lastRxDuration: UInt64 = 0
    var lastErrorCount: UInt32 = 0

    var testSettings: TestSettings?
    var logTimer: Timer?

    lazy var server: Server = Server() { [unowned self] messageType in

        guard self.server.isOn else {
            self.server.write(message: "Server is off. Please start server")
            return
        }
        self.server.write(message: "")
        switch messageType {
        case .help(var name):
            if let name = name {
                switch name {
                case "scan":
                    self.server.write(message: "This command scans area for specified time and shows all visible peripherals.")
                    self.server.write(message: "How to use it:")
                    self.server.write(message: "scan [$time]")
                    self.server.write(message: "Scans for $time. Default time is 5s.\n")
                case "stop":
                    self.server.write(message: "This command stops all tasks on the iPhone.")
                    self.server.write(message: "How to use it:")
                    self.server.write(message: "stop\n")
                case "test":
                    self.server.write(message: "This command starts test.")
                    self.server.write(message: "How to use it:")
                    self.server.write(message: "test deviceName [args ...] ")
                    self.server.write(message: "Possible args: ")
                    self.server.write(message: "tx - shows tx stats during test ")
                    self.server.write(message: "rx - shows rx stats during test ")
                    self.server.write(message: "credits - runs test using credits")
                    self.server.write(message: "packagesize=[$size] - runs test using $size as packagesize. Default $size is 20")
                    self.server.write(message: "bytecount=[$size] - sends $size bytes in one test request. Default $size is infinity (runs continuous DataPump)\n")
                default:
                    self.server.write(message: "Unknown command. \n")
                }
            } else {
                self.server.write(message: "Supported commands:")
                self.server.write(message: "- help")
                self.server.write(message: "- scan")
                self.server.write(message: "- stop")
                self.server.write(message: "- test")
                self.server.write(message: "Use help $commandName for more info on how to use this command. \n")
            }
        case .scan(let time):
            BluetoothManager.shared.peripherals = []
            BluetoothManager.shared.isScanningForPeripherals = true
            self.server.write(message: "Scanning...")
            Timer.scheduledTimer(withTimeInterval: time ?? 5, repeats: false, block: { _ in
                BluetoothManager.shared.isScanningForPeripherals = false
                self.showFoundPeripherals()
            })
        case .stop:
            if BluetoothManager.shared.isScanningForPeripherals {
                BluetoothManager.shared.isScanningForPeripherals = false
                self.showFoundPeripherals()
            }
            if self.dataPump?.isRunning ?? false {
                self.dataPump?.stop()
                self.logTimer?.invalidate()
                BluetoothManager.shared.currentSerialPort?.close()
                guard let peripheral = BluetoothManager.shared.currentPeripheral else {
                    return
                }
                BluetoothManager.shared.disconnect(peripheral)
                self.reportResults()
            }
        case .test(let testSettings):
            self.testSettings = testSettings
            if let peripheral = BluetoothManager.shared.currentPeripheral {
                BluetoothManager.shared.disconnect(peripheral)
            }
            BluetoothManager.shared.peripherals = []
            BluetoothManager.shared.isScanningForPeripherals = true
            self.server.write(message: "Connecting...")
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
                BluetoothManager.shared.isScanningForPeripherals = false
                for peripheral in BluetoothManager.shared.peripherals {
                    guard let name = peripheral.name?.replacingOccurrences(of: " ", with: "_"),
                          name == testSettings.deviceName else {
                        continue
                    }
                    BluetoothManager.shared.connect(peripheral) {
                        guard let testSettings = self.testSettings else {
                            self.server.write(message: "Unknown error occured")
                            return
                        }
                        self.openSerialPort(withSettings: testSettings)
                    }
                    return
                }
                self.testSettings = nil
                self.server.write(message: "Couldnt find peripheral with name: \(testSettings.deviceName!) ")
                self.server.write(message: "")
            })
        case .unknown:
            self.log(message: "Unknown command.")
            self.server.write(message: "Unknown command. Use \"help\" for more details.")
        }
    }
    func showFoundPeripherals() {
        self.server.write(message: "Found peripherals:")
        var index = 0
        for peripheral in BluetoothManager.shared.peripherals {
            guard let name = peripheral.name?.replacingOccurrences(of: " ", with: "_") else {
                continue
            }
            self.server.write(message: "\(index). \(name)")
            index += 1
        }
        self.server.write(message: "")
    }
    
    func reportResults() {
        server.write(message: "RESULTS:")
        server.write(message: "TX Count (B): \(lastTxCount)")
        server.write(message: "TX Duration (ns): \(lastTxDuration)")
        server.write(message: "RX Count (B): \(lastRxCount)")
        server.write(message: "RX Duration (ns): \(lastRxDuration)")
        server.write(message: "RX Error count: \(lastErrorCount)")
    }
}

extension ServerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        loggingTextView.layer.borderWidth = 1
        loggingTextView.layer.borderColor = UIColor.black.cgColor
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if server.isOn {
            server.stop()
        }
    }
}
extension ServerViewController {
    func log(message: String) {
        DispatchQueue.main.async {
            let text = self.loggingTextView.text != nil ? "\(self.loggingTextView.text!)\n" : ""
            self.loggingTextView.text = text + message
            let bottom = NSRange(location: self.loggingTextView.text.count-1, length: 1)
            self.loggingTextView.scrollRangeToVisible(bottom)
        }
    }
}

extension ServerViewController: UbloxSerialPortDelegate {

    fileprivate func openSerialPort(withSettings settings: TestSettings) {
        self.log(message: "Connecting SPS...")
        BluetoothManager.shared.setupSerialPort { [unowned self] in
            guard let serialPort = BluetoothManager.shared.currentSerialPort else {
                return
            }
            serialPort.delegate = self
            serialPort.withFlowControl = settings.testingCredits
            self.dataPump = DataPump(stream: serialPort, delegate: self)
            self.dataPump!.packetSize = settings.packageSize

            BluetoothManager.shared.currentSerialPort?.open()
        }
    }

    func serialPortDidUpdateState(_ serialPort: UbloxSerialPort) {
        guard serialPort.state == .open else {
            return
        }
        self.log(message: "SPS Connected.")
        self.server.write(message: "Connected.")
        self.log(message: "Start test.")
        self.server.write(message: "Testing...")
        logTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.logTests()
        }
        self.dataPump?.start(continuous: true)
    }
    func logTests() {
        DispatchQueue.main.async {
            if self.testSettings?.showTx ?? false {
                self.log(message: "TX: \(self.lastTxCount)")
            }
            if self.testSettings?.showRx ?? false {
                self.log(message: "RX: \(self.lastRxCount)")
                self.log(message: "RX ERRORS: \(self.lastErrorCount)")
            }
        }
    }
}
extension ServerViewController : DataPumpDelegate {
    func onTx(bytes: UInt64, duration: UInt64) {
        lastTxCount = bytes
        lastTxDuration = duration
    }
    
    func onRx(bytes: UInt64, duration: UInt64) {
        lastRxCount = bytes
        lastRxDuration = duration
    }
    
    func onRxError(errorCount: UInt32) {
        lastErrorCount = errorCount
    }
}
