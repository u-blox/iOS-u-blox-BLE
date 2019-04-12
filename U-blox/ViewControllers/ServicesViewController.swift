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

class ServicesViewController: BaseTabBarViewController {

    @IBOutlet weak var tableView: UITableView!

    var services: [CBService] {
        return BluetoothManager.shared.currentPeripheral?.services ?? []
    }
}

extension ServicesViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forType: .serviceDiscovered, object: nil, queue: .main) { [weak self] notification in
            self?.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }
}
extension ServicesViewController: UITableViewDelegate, UITableViewDataSource {
    private struct SegueIdentifiers {
        static let detail = "detail"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServicesTableViewCell.reuseIdentifier) as! ServicesTableViewCell//crash
        if services.count > indexPath.row {
            let service = services[indexPath.row]
            cell.nameLabel.text = service.ubloxDescription
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifiers.detail, sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SegueIdentifiers.detail?:
            let dvc = segue.destination as! ServicesDetailViewController
            dvc.serviceUUID = BluetoothManager.shared.currentPeripheral!.services[tableView.indexPathForSelectedRow!.row].uuid.uuidString
        default: break
        }
        tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
    }
}
