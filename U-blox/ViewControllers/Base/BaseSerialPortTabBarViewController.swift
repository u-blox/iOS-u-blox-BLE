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

class BaseSerialPortTabBarViewController: BaseTabBarViewController {

    var setupSerialPortComplitionHandler: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let peripheral = BluetoothManager.shared.currentPeripheral,
              peripheral.isSupportingSerialPort else {
                let alert = AlertUtil.createAlert(type: .basic, title: "Sorry", message: "\(BluetoothManager.shared.currentPeripheral?.name ?? "Peripheral") does now support Serial Port.", action: nil)
                self.present(alert, animated: true, completion: nil)
                return
        }

        showPendingAlert(title: "Connecting SPS...", buttonAction: nil)
        BluetoothManager.shared.setupSerialPort {
            BluetoothManager.shared.currentSerialPort?.delegate = self
            BluetoothManager.shared.currentSerialPort?.open()
            self.setupSerialPortComplitionHandler?()
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        BluetoothManager.shared.currentSerialPort?.close()
    }
}

extension BaseSerialPortTabBarViewController: UbloxSerialPortDelegate {
    func serialPortDidUpdateState(_ serialPort: UbloxSerialPort) {
        guard serialPort.state == .open else {
            return
        }
        dismissPendingAlert()
    }
}
