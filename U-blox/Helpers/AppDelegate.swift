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

let kMeshEnabled = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UITabBarItem.appearance().setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.ublox.withBrightness(1)
            ], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.white
            ], for: .selected)
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().barTintColor = .ublox
        
        UISwitch.appearance().onTintColor = UIColor.ublox
        
        window?.tintColor = UIColor.ublox.withBrightness(0.8)
        window?.makeKeyAndVisible()
        window?.backgroundColor = .ublox
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        defaults.synchronize()
    }

}

