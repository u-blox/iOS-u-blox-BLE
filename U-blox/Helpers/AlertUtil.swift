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

enum AlertType {
    case basic, withActivityIndicator
}

struct AlertUtil {
    static func createAlert(type: AlertType, title: String? = nil, message: String? = nil, action: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        switch type {
        case .basic:
            return createBasicAlert(title: title, message: message, action: action)
        case .withActivityIndicator:
            return createAlertWithActivityIndicator(title: title, message: (message ?? "") + "\n\n\n\n\n", action: action)
        }
    }
    private static func createBasicAlert(title: String?, message: String?, action: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: action))
        return alertController
    }
    private static func createAlertWithActivityIndicator(title: String?, message: String?, action: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let action = action {
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: action))
        }
        let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
        indicator.activityIndicatorViewStyle = .gray
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        alertController.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false
        indicator.startAnimating()
        return alertController
    }
}

