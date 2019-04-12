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

class InfoViewController: BaseViewController {

    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func linkButtonPressed(_ sender: Any) {
        guard let url = URL(string: InfoConstants.ubloxURL) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        guard let version = Bundle.main.object(forInfoDictionaryKey: InfoConstants.shortVersionKey) as? String else {
            return
        }
        versionLabel.text = version
    }
}

fileprivate extension InfoViewController {
    struct InfoConstants {
        static let ubloxURL = "http://u-blox.com"
        static let shortVersionKey = "CFBundleShortVersionString"
    }
}
