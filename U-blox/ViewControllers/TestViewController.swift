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

class TestViewController: BaseSerialPortTabBarViewController {

    @IBOutlet weak var packetSizeTextField: UITextField!
    @IBOutlet weak var maxPacketLabel: UILabel!
    @IBOutlet weak var txBytesLabel: UILabel!
    @IBOutlet weak var txRateLabel: UILabel!
    @IBOutlet weak var rxBytesLabel: UILabel!
    @IBOutlet weak var rxRateLabel: UILabel!
    @IBOutlet weak var rxErrorsLabel: UILabel!
    @IBOutlet weak var creditsSwitch: UISwitch!
    @IBOutlet weak var testModeTextField: UITextField!

    @IBOutlet weak var txClearButton: UIButton!
    @IBOutlet weak var rxClearButton: UIButton!
    @IBOutlet weak var startTestButton: UIButton!
    
    lazy var picker: UIPickerView = {
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 200, width: view.frame.width, height: 300))
        pickerView.backgroundColor = .white
        pickerView.showsSelectionIndicator = true
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    lazy var pickerToolbar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = .ublox
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(pickerDoneButtonPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(pickerCancelButtonPressed))

        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        return toolBar
    }()

    @objc func pickerCancelButtonPressed(_ sender: Any) {
        testModeTextField.resignFirstResponder()
    }
    
    @objc func pickerDoneButtonPressed(_ sender: Any) {
        testMode = TxTestMode.allValues[picker.selectedRow(inComponent: 0)]
        testModeTextField.resignFirstResponder()
    }

    @IBAction func clearTxButtonPressed(_ sender: Any) {
        txRateLabel.text = "0.0 kbps"
        txBytesLabel.text = "0 B"
        dataPumpManager?.resetTx()
    }

    @IBAction func clearRxButtonPressed(_ sender: Any) {
        rxRateLabel.text = "0.0 kbps"
        rxBytesLabel.text = "0 B"
        rxErrorsLabel.text = "0"
        dataPumpManager?.resetRx()
    }

    @IBAction func creditsSwitchValueChanged(_ sender: UISwitch) {
        dataPumpManager?.stop()
        showPendingAlert(title: "Setting up credits...", buttonAction: nil)
        BluetoothManager.shared.currentSerialPort?.close()
        BluetoothManager.shared.setupSerialPort {
            BluetoothManager.shared.currentSerialPort?.delegate = self
            BluetoothManager.shared.currentSerialPort?.withFlowControl = sender.isOn
            BluetoothManager.shared.currentSerialPort?.open()
            self.setupSerialPortComplitionHandler?()
        }
    }

    @IBAction func closeKeyboardPressed(_ sender: Any) {
        guard packetSizeTextField.isFirstResponder || testModeTextField.isFirstResponder else {
            return
        }
        view.endEditing(true)
        let maxPackageSize = BluetoothManager.shared.currentPeripheral?.maximumWriteValueLength ?? 0
        guard let packageSizeText = packetSizeTextField.text,
              let packageSize = Int(packageSizeText),
              packageSize <= maxPackageSize else {
                packetSizeTextField.text = "\(maxPackageSize)"
                let alert = AlertUtil.createAlert(type: .basic, title: "Sorry", message: "Provided MTU is not in range: 0-\(maxPackageSize)", action: nil)
                present(alert, animated: true, completion: nil)
            return
        }
        dataPumpManager?.packetSize = packageSize
    }

    @IBAction func startStopTestButtonPressed(_ sender: UIButton) {
        if dataPumpManager?.isRunning ?? false {
            dataPumpManager?.stop()
            sender.setTitle("Start Test", for: .normal)
            isUIEnabled = true
            return
        }
        switch testMode {
        case .continuous:
            isUIEnabled = false
            sender.setTitle("Stop Test", for: .normal)
            dataPumpManager?.start(continuous: true)
        case .onePacket:
            dataPumpManager?.start(continuous: false)
        }
    }

    var testMode: TxTestMode {
        get {
            guard let testMode = TxTestMode(rawValue: testModeTextField.text ?? "") else {
                return .continuous
            }
            return testMode
        }
        set {
            testModeTextField.text = newValue.rawValue
        }

    }

    var isUIEnabled = true {
        didSet {
            packetSizeTextField.isEnabled = isUIEnabled
            creditsSwitch.isEnabled = isUIEnabled
            testModeTextField.isEnabled = isUIEnabled
        }
    }

    var isViewEnabled = true {
        didSet {
            creditsSwitch.isEnabled = isUIEnabled
            rxClearButton.isEnabled = isViewEnabled
            txClearButton.isEnabled = isViewEnabled
            startTestButton.isEnabled = isViewEnabled
        }
    }
    
    var dataPumpManager: DataPump?
}

extension TestViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        packetSizeTextField.delegate = self
        testModeTextField.delegate = self

        testModeTextField.inputView = picker
        testModeTextField.inputAccessoryView = pickerToolbar
        isViewEnabled = BluetoothManager.shared.currentPeripheral?.isSupportingSerialPort ?? false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let currentPeripheral = BluetoothManager.shared.currentPeripheral else {
            maxPacketLabel.text = "NOT CONNECTED"
            return
        }
        let maximumWriteValueLength = currentPeripheral.maximumWriteValueLength
        maxPacketLabel.text = "(Max: \(maximumWriteValueLength))"
        packetSizeTextField.text = "\(maximumWriteValueLength)"
        
        setupSerialPortComplitionHandler = {
            self.dataPumpManager = DataPump(stream: BluetoothManager.shared.currentSerialPort!, delegate: self)
            self.dataPumpManager?.packetSize = maximumWriteValueLength
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataPumpManager?.stop()
    }
}

extension TestViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TxTestMode.allValues.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return TxTestMode.allValues[row].rawValue
    }
}

extension TestViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isViewEnabled = false
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        isViewEnabled = true
    }
}

extension TestViewController : DataPumpDelegate {
    func onTx(bytes: UInt64, duration: UInt64) {
        txBytesLabel.text = transferAmount(bytes: bytes)
        txRateLabel.text = transferRate(bytes: bytes, duration: duration)
        guard let running = dataPumpManager?.isRunning, !running else {
            return
        }
        startTestButton.setTitle("Start Test", for: .normal)
        isUIEnabled = true
    }
    
    func onRx(bytes: UInt64, duration: UInt64) {
        rxBytesLabel.text = transferAmount(bytes: bytes)
        rxRateLabel.text = transferRate(bytes: bytes, duration: duration)
    }
    
    func onRxError(errorCount: UInt32) {
        rxErrorsLabel.text = "\(errorCount)"
    }
    
    func transferAmount(bytes: UInt64) -> String {
        guard bytes > 1024 else {
            return "\(bytes) B"
        }
        var b = Double(bytes) / 1024
        guard b > 1024 else {
            return "\(twoDecimals(val: b)) KB"
        }
        b /= 1024
        guard b > 1024 else {
            return "\(twoDecimals(val: b)) MB"
        }
        b /= 1024
        return "\(twoDecimals(val: b)) GB"
    }
    
    func transferRate(bytes: UInt64, duration: UInt64) -> String {
        let kiloBits = 8*Double(bytes) / 1024
        let seconds = Double(duration) / 1000000000
        return "\(twoDecimals(val: kiloBits / seconds)) kbps"
    }
    
    func twoDecimals(val: Double) -> Double {
        var value = 100*val + 0.5
        let trunc = Int(value)
        value = Double(trunc) / 100
        return value
    }
}
