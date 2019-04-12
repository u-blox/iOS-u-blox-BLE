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

class ScanViewController: BaseViewController {

    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var scanIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        isScanning = !BluetoothManager.shared.isScanningForPeripherals
    }
    @IBAction func clearButtonPressed(_ sender: Any) {
        clearTableView()
    }

    var isScanning: Bool = false {
        didSet{
            BluetoothManager.shared.isScanningForPeripherals = isScanning
            switch isScanning {
            case true:
                scanButton.setTitle("Scanning...", for: .normal)
                scanIndicator.isHidden = false
            case false:
                scanButton.setTitle("Start scan", for: .normal)
                scanIndicator.isHidden = true
            }
        }
    }
    fileprivate var status: ConnectionStatus = .disconnected {
        didSet {

            let selectedIndexPath = tableView.indexPathForSelectedRow
            if selectedIndexPath != nil {
                tableView.deselectRow(at: selectedIndexPath!, animated: true)
            }
            switch status {
            case .connected:
                dismissPendingAlert(completion: {
                    self.present(UIStoryboard(name: "Scan", bundle: nil).instantiateInitialViewController()!, animated: true, completion: nil)
                })
            case .connecting:
                showPendingAlert(title: "Connecting...", buttonAction: { _ in
                    guard let selectedRow = selectedIndexPath?.row else {
                        return
                    }
                    let peripheral = BluetoothManager.shared.peripherals[selectedRow]
                    BluetoothManager.shared.disconnect(peripheral)
                })
            case .disconnected, .connectionFailed: break
            }
        }
    }
}

extension ScanViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        clearTableView()

        NotificationCenter.default.addObserver(forType: .peripheralDisconnected, object: nil, queue: .main, using: { [weak self] _ in
            self?.status = .disconnected
        })

        NotificationCenter.default.addObserver(forType: .peripheralConnectionFailed, object: nil, queue: .main, using: { [weak self] notification in
            self?.dismissPendingAlert(completion: {
                let peripheralName = notification.userInfo?[UbloxDictionaryKeys.name] as! String
                let alert = AlertUtil.createAlert(type: .basic ,title: "\(peripheralName) failed to connect", message: nil)
                self?.present(alert, animated: true, completion: nil)
            })
        })
        [UbloxNotificationTypes.peripheralListChanged, .peripheralUpdated].forEach { type in
            NotificationCenter.default.addObserver(forType: type, object: nil, queue: .main, using: { [weak self] _ in self?.tableView.reloadData()})
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        isScanning = false

        NotificationCenter.default.removeObserver(self)
    }
}

extension ScanViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ScanTableViewCell.reuseIdentifier) as! ScanTableViewCell
        let peripheral = BluetoothManager.shared.peripherals[indexPath.row]

        cell.nameLabel.text = peripheral.name
        cell.idLabel.text = peripheral.identifier.uuidString
        guard let rssi = peripheral.rssi else {
            return cell
        }
        cell.signalIcon.image = IconUtil.icon(forRssi: rssi)
        if rssi == NSNumber(value: 127) || rssi == NSNumber(value: -999) {
            cell.rssiLabel.text = "GONE"
        } else {
            cell.rssiLabel.text = "\(rssi) dBm"
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BluetoothManager.shared.peripherals.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard status == .disconnected else {
            return
        }
        let peripheral = BluetoothManager.shared.peripherals[indexPath.row]
        BluetoothManager.shared.connect(peripheral) { self.status = .connected }
        status = .connecting
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

extension ScanViewController {
    fileprivate enum ConnectionStatus {
        case disconnected, connectionFailed, connected, connecting
    }
    func clearTableView() {
        isScanning = false
        if let peripheral = BluetoothManager.shared.currentPeripheral {
            BluetoothManager.shared.disconnect(peripheral)
        }
        BluetoothManager.shared.peripherals = []
        tableView.reloadData()
    }
}

