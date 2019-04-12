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
import SceneKit
import CoreBluetooth

class OverviewViewController: BaseTabBarViewController {

    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var batteryLevelLabel: UILabel!
    @IBOutlet weak var accelerometerRangeLabel: UILabel!

    @IBOutlet weak var modelButton: UIButton!

    @IBOutlet weak var modelScene: SCNView!

    @IBOutlet weak var redLedSwitch: UISwitch!
    @IBOutlet weak var greenLedSwitch: UISwitch!

    @IBOutlet weak var xProgressView: UIProgressView!
    @IBOutlet weak var yProgressView: UIProgressView!
    @IBOutlet weak var zProgressView: UIProgressView!

    @IBOutlet weak var modelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var modelTopConstraint: NSLayoutConstraint!

    private enum LedTag: Int {
        case red = 1
        case green = 2
    }
    @IBAction func ledSwitchValueChanged(_ sender: UISwitch) {
        guard let ledColor = LedTag(rawValue: sender.tag),
              let currentPeripheral = BluetoothManager.shared.currentPeripheral else {
            return
        }
        let value: Byte = sender.isOn ? 1 : 0
        var ubloxCharacteristic: UbloxCharacteristic
        switch ledColor {
        case .red:
            ubloxCharacteristic = .ledRed
        case .green:
            ubloxCharacteristic = .ledGreen
        }
        currentPeripheral.write(bytes: [value], for: ubloxCharacteristic, type: .withResponse)
    }

    @IBAction func modelButtonPressed(_ sender: Any) {
        modelScene.isHidden = !modelScene.isHidden
        modelButton.setTitle(modelScene.isHidden ? "3D" : "Accelerometer", for: .normal)
    }

    @IBAction func modelTapped(_ sender: Any) {
        modelTopConstraint.constant =
            modelHeightConstraint.constant == Constants.modelHeightDefaultValue ?
            0 : Constants.modelTopDefaultValue

        modelHeightConstraint.constant =
            modelHeightConstraint.constant == Constants.modelHeightDefaultValue ?
            self.view.bounds.size.height : Constants.modelHeightDefaultValue

        modelScene.setNeedsUpdateConstraints()
        modelScene.layoutIfNeeded()

        DispatchQueue.main.async {
            self.model.model.eulerAngles = self.model.model.eulerAngles.moved(by: SCNVector3(0.1, 0, 0))
        }
    }

    @IBAction func modelLongPressed(_ sender: Any) {
        let vector = SCNVector3(-Int(model.accelerometer.x), Int(model.accelerometer.y), Int(model.accelerometer.z))
        DispatchQueue.main.async {
            self.model.model.eulerAngles = vector.eulerAngleCalculated
        }

    }

    fileprivate var model = OverviewModel()
    fileprivate let supportedCharacteristics: [UbloxCharacteristic] = [
        .ledRed, .ledGreen,
        .temperature, .battery,
        .accelerometerRange, .accelerometerX, .accelerometerY, .accelerometerZ,
        .gyroscopeX, .gyroscopeY, .gyroscopeZ, .gyroscope
    ]
}

extension OverviewViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        modelScene.scene = model.sceneWithLights
        modelScene.allowsCameraControl = true
        modelScene.backgroundColor = .black

        NotificationCenter.default.addObserver(self, selector: #selector(characteristicValueUpdated), type: .characteristicValueUpdated, object: nil)
        NotificationCenter.default.addObserver(forType: .rssiUpdated, object: nil, queue: .main) { [weak self] notification in
            guard let rssi = notification.userInfo?[UbloxDictionaryKeys.rssi] as? NSNumber else {
                return
            }
            self?.rssiLabel.text = "\(rssi) dBm"
        }

        setupView()
    }

    private func setupView() {
        temperatureLabel.text = ""
        rssiLabel.text = ""
        batteryLevelLabel.text = ""
        accelerometerRangeLabel.text = ""

        redLedSwitch.isOn = false
        greenLedSwitch.isOn = false

        modelButton.isHidden = true
        modelScene.isHidden = true

        for progressView in [xProgressView, yProgressView, zProgressView] {
            progressView?.setProgress(0, animated: false)
        }

        guard let currentPeripheral = BluetoothManager.shared.currentPeripheral else {
            return
        }

        BluetoothManager.shared.currentCharacteristicsHandler = CharacteristicSniffer(for: currentPeripheral, readAndNotify: supportedCharacteristics, onlyRead: [.modelNumber])
        currentPeripheral.discoverServices(nil)
    }
}

// MARK: Selectors

extension OverviewViewController {

    @objc func characteristicValueUpdated(notification: NSNotification) {

        guard let characterisitic = notification.userInfo?[UbloxDictionaryKeys.characteristic] as? CBCharacteristic,
              let ubloxCharacteristic = notification.userInfo?[UbloxDictionaryKeys.ubloxCharacteristic] as? UbloxCharacteristic,
              let ubloxPeripheral = notification.userInfo?[UbloxDictionaryKeys.ubloxPeripheral] as? UbloxPeripheral,
              let characteristicValue = characterisitic.value?.byteArray else {
                return
        }

        if ubloxCharacteristic == .modelNumber {
            if let modelName = String(data: characterisitic.value ?? Data(), encoding: .utf8),
               modelName.hasPrefix("NINA-B1") {
                modelButton.isHidden = false
                modelScene.isHidden = false
                modelButton.setTitle("Accelerometer", for: .normal)
            }
        }

        guard let currentPeripheral = BluetoothManager.shared.currentPeripheral,
              ubloxPeripheral == currentPeripheral else {
            return
        }

        switch ubloxCharacteristic {
        case .gyroscope:
            /*
             [0] = acc/gyro_x
             [1] = acc/gyro_y
             [2] = acc/gyro_z

             [3] = timestamp[24:16]
             [4] = timestamp[15:8]
             [5] = timestamp[7:0]
             */
            let timeValue = (UInt32(characteristicValue[3]) << 16) | (UInt32(characteristicValue[4]) << 8) | UInt32(characteristicValue[5])
            let diff = timeValue - model.lastGyroscopeMeasurementTime
            model.lastGyroscopeMeasurementTime = timeValue

            guard diff <= 5000 else {
                return
            }
            let passedTime = Float(diff)/1000000*39 // Todo: 'sup with these magic numbers...

            let angleRotX = Float(Int8(bitPattern: characteristicValue[0]))/64*360*passedTime
            let angleRotY = Float(Int8(bitPattern: characteristicValue[1]))/64*360*passedTime
            let angleRotZ = Float(Int8(bitPattern: characteristicValue[2]))/64*360*passedTime

            let angleX = SCNMatrix4MakeRotation(AngleUtil.convert(value: angleRotY, from: .degree, to: .radian), 1, 0, 0)
            let angleY = SCNMatrix4MakeRotation(AngleUtil.convert(value: angleRotZ, from: .degree, to: .radian), 0, 1, 0)
            let angleZ = SCNMatrix4MakeRotation(AngleUtil.convert(value: angleRotX, from: .degree, to: .radian), 0, 0, 1)

            let rotationMatrix = SCNMatrix4Mult(SCNMatrix4Mult(angleX, angleY), angleZ)

            DispatchQueue.main.async {
                self.model.model.transform = SCNMatrix4Mult(rotationMatrix, self.model.model.transform)
            }

        case .accelerometerX:
            model.accelerometer.x = characteristicValue.first ?? 0
            xProgressView.setProgress((Float(Int8(bitPattern: model.accelerometer.x)) + 128) / 256, animated: true)
        case .accelerometerY:
            model.accelerometer.y = characteristicValue.first ?? 0
            yProgressView.setProgress((Float(Int8(bitPattern: model.accelerometer.y)) + 128) / 256, animated: true)
        case .accelerometerZ:
            model.accelerometer.z = characteristicValue.first ?? 0
            zProgressView.setProgress((Float(Int8(bitPattern: model.accelerometer.z)) + 128) / 256, animated: true)
        case .accelerometerRange:
            var range = characteristicValue[0]
            if (characteristicValue.count > 1) {
                range |= characteristicValue[1] << 8
            }
            accelerometerRangeLabel.text = "+-\(range)G"
        case .temperature:
            temperatureLabel.text = "\(characteristicValue.first ?? 0) °C"
        case .battery:
            batteryLevelLabel.text = "\(characteristicValue.first ?? 0)%"
        case .ledRed:
            redLedSwitch.isEnabled = true
            redLedSwitch.isOn = characteristicValue.first != 0
        case .ledGreen:
            greenLedSwitch.isEnabled = true
            greenLedSwitch.isOn = characteristicValue.first != 0
        default: break
        }
    }
}

fileprivate extension OverviewViewController {
    struct Constants {
        static let modelTopDefaultValue: CGFloat = 180
        static let modelHeightDefaultValue: CGFloat = 115
    }
}

struct OverviewModel {
    unowned var model: SCNNode
    var sceneWithLights: SCNScene
    var accelerometer = Accelerometer()
    var lastGyroscopeMeasurementTime: UInt32 = 0

    init() {
        let scene = SCNScene(named: "art.scnassets/NINA-B112.obj")!

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 25)
        scene.rootNode.addChildNode(cameraNode)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray.cgColor
        scene.rootNode.addChildNode(ambientLightNode)

        model = scene.rootNode.childNodes[0]
        sceneWithLights = scene
    }
}
class Accelerometer: BaseMeasureDevice {}
class BaseMeasureDevice {
    var x: Byte = 0
    var y: Byte = 0
    var z: Byte = 0
}

fileprivate extension SCNVector3 {
    var eulerAngleCalculated: SCNVector3 {
        return SCNVector3(
            z > 0 ? atan(x/sqrt(pow(y, 2)+pow(z, 2))) : (atan(-x/sqrt(pow(y, 2)+pow(z, 2))) + .pi),
            0,
            atan(y/sqrt(pow(x, 2)+pow(z, 2))))
    }
    func moved(by vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(x+vector.x, y+vector.y, z+vector.z)
    }
}

enum AngleUnit {
    case radian
    case degree
}
struct AngleUtil {
    static func convert(value: Float, from unit: AngleUnit, to destinationUnit: AngleUnit) -> Float {
        switch (unit, destinationUnit) {
        case (.degree, .radian):
            return value / 180 * .pi
        case (.radian, .degree):
            return value * 180 * .pi
        default:
            return value
        }
    }
}
