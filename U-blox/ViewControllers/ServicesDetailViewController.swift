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

class ServicesDetailViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!

    var serviceUUID: String!

}

extension ServicesDetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forType: .characteristicValueUpdated, object: nil, queue: .current) { [weak self] notification in
            guard let notificationCharacteristic = notification.userInfo?[UbloxDictionaryKeys.characteristic] as? CBCharacteristic else {
                return
            }
            let service = BluetoothManager.shared.currentPeripheral?.services.first { $0.uuid.uuidString == self?.serviceUUID && self?.serviceUUID != nil }
            for (index, characteristic) in (service?.characteristics ?? []).enumerated() where characteristic.uuid.uuidString == notificationCharacteristic.uuid.uuidString {
                DispatchQueue.main.async {
                    let indexPath = IndexPath(row: index, section: 0)
                    if let cell = self?.tableView.cellForRow(at: indexPath) as? ServicesDetailTableViewCell {
                        cell.valueLabel.text = characteristic.ubloxValueDescription
                    }
                }
            }
        }
        BluetoothManager.shared.currentPeripheral!.services.first { $0.uuid.uuidString == self.serviceUUID }?
            .characteristics?.forEach( BluetoothManager.shared.currentPeripheral!.readValue)
    }
}

extension ServicesDetailViewController: UITableViewDelegate, UITableViewDataSource {
    private struct SegueIdentifiers {
        static let edit = "edit"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BluetoothManager.shared.currentPeripheral?.services.first { $0.uuid.uuidString == serviceUUID }?.characteristics?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServicesDetailTableViewCell.reuseIdentifier) as! ServicesDetailTableViewCell
        if let service = BluetoothManager.shared.currentPeripheral?.services.first(where: { $0.uuid.uuidString == self.serviceUUID }),
           let characteristic = service.characteristics?[indexPath.row] {
            cell.nameLabel.text = characteristic.ubloxDescription
            cell.valueLabel.text = characteristic.ubloxValueDescription
            cell.typeLabel.text = characteristic.properties.ubloxDescription
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifiers.edit, sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SegueIdentifiers.edit?:
            let dvc = segue.destination as! EditViewController
            dvc.serviceUUID = serviceUUID
            dvc.characteristicUUID = BluetoothManager.shared.currentPeripheral?.services.first { $0.uuid.uuidString == serviceUUID }?.characteristics?[tableView.indexPathForSelectedRow!.row].uuid.uuidString
        default: break
        }
        tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
    }
}

