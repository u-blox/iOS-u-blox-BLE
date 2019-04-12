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
import CoreBluetooth

class EditViewController: BaseViewController {

    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var characteristicLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var textTextField: UITextField!
    @IBOutlet weak var hexTextField: UITextField!
    @IBOutlet weak var intTextField: UITextField!

    var serviceUUID: String!
    var characteristicUUID: String!

}

extension EditViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let currentPeripheral = BluetoothManager.shared.currentPeripheral,
            let service = currentPeripheral.services.first(where: { $0.uuid.uuidString == self.serviceUUID }),
            let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == self.characteristicUUID }) {

            serviceLabel.text = service.ubloxDescription
            characteristicLabel.text = characteristic.ubloxDescription
            valueLabel.text = characteristic.ubloxValueDescription
            currentPeripheral.setNotify(true, for: characteristic)

            if characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write) {
                textTextField.isHidden = false
                hexTextField.isHidden = false
                intTextField.isHidden = false
            }
        }
        NotificationCenter.default.addObserver(forType: .characteristicValueUpdated, object: nil, queue: .current) { [weak self] notification  in
            guard let characteristic = notification.userInfo?[UbloxDictionaryKeys.characteristic] as? CBCharacteristic,
                  characteristic.uuid.uuidString == self?.characteristicUUID else {
                    return
            }
            DispatchQueue.main.async {
                self?.valueLabel.text = "\(characteristic.value!)"
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)

        guard let peripheral = BluetoothManager.shared.currentPeripheral,
            let characteristic = peripheral.services.first(where: { $0.uuid.uuidString == serviceUUID })?.characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID }) else {
            return
        }
        peripheral.setNotify(false, for: characteristic)
    }
}
extension EditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let peripheral = BluetoothManager.shared.currentPeripheral,
              let characteristic = peripheral.services.first(where: { $0.uuid.uuidString == serviceUUID})?
                .characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID}) else {
                    return true
        }
        textField.resignFirstResponder()
        var data: Data?
        switch textField {
        case textTextField:
            guard let utf8View = textField.text?.utf8 else {
                    return true
            }
            data = Data(bytes: [Byte](utf8View))
        case hexTextField:
            guard let hexArr = textField.text?.hexArray else {
                return true
            }
            data = NSData(bytes: hexArr, length: hexArr.count) as Data
        case intTextField:
            var value = Int(textField.text ?? "")
            data = NSData(bytes: &value, length: 1) as Data
        default: break
        }

        guard let writeData = data else {
            return true
        }

        if characteristic.properties.contains(.write) {
            peripheral.write(writeData, for: characteristic, type: .withResponse)
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            peripheral.write(writeData, for: characteristic, type: .withoutResponse)
        }

        return true
    }
}


