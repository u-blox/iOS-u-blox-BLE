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
import nRFMeshProvision

private let kSmallCellHeight = 40 as CGFloat
private let kMediumCellHeight = 60 as CGFloat
private let kBigCellHeight = 90 as CGFloat
private let kLEDCellHeight = 142 as CGFloat // Picked from ColorPickerController.xib
private let kHugeCellHeight = 240 as CGFloat

let kTableInset = 16 as CGFloat

protocol BaseCellDelegate: class {
    func nodeRenamed()
    var historyLimit: HistoryLimit { get }
}

/// Base class for all node detail varieties.
class BaseCell: UITableViewCell {
    class var title: String? { nil }
    class var height: CGFloat { kSmallCellHeight }
    class var reuseId: String { self.description() }
    final var indexPath: IndexPath!
    weak var node: UbloxNode?
    final weak var delegate: BaseCellDelegate?
    var tappableInOverview: Bool { true }
    var tappableInDetail: Bool { false }
    func update(animated: Bool = false) { }
    func configure() { }
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = UIView.colored(.selection)
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

/// Cell for displaying an editable node title.
class EditableNameCell: BaseCell, UITextFieldDelegate {
    override class var height: CGFloat { kMediumCellHeight }
    var textField: UITextField!
    
    override func configure() {
        if textField == nil {
            textField = UITextField(frame: self.contentView.bounds.insetBy(dx: 8, dy: 8))
            textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            textField.delegate = self
            textField.placeholder = "Enter a name"
            textField.clearButtonMode = .always
            textField.borderStyle = .roundedRect
            textField.returnKeyType = .done
            self.contentView.addSubview(textField)
        }
        textField?.text = node?.name
    }
    
    /// Saves new node alias and tells delegate so view controller title can be updated.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let name = textField.text ?? ""
        if name.count > 0 { node?.name = name }
        else { node?.removeName() }
        delegate?.nodeRenamed()
        textField.resignFirstResponder()
        return true
    }
}

/// Base class for cells interested in any mesh messages from nodes.
class DynamicCell: BaseCell {
    override weak var node: UbloxNode? {
        willSet { node?.removeRequestCell(self) }
        didSet { node?.addRequestCell(self)}
    }
    
    var requestStatusTypes: [MeshMessage.Type]? { nil }
    
    /// Called when node has received a message of a type in requestStatusTypes.
    final func handleStatus(requestNode: UbloxNode) {
        if requestNode == node {
            update(animated: true)
        }
    }
    
    /// Avoids retain cycles between node and cell when removing table view.
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        node = nil
    }
}

/// Base class for cells displaying sensor data.
class SensorCell: DynamicCell {
    override class var title: String? { sensorTypes.map { $0.title }.joined(separator: ", ") }
    override var requestStatusTypes: [MeshMessage.Type] { [SensorServerStatus.self, SimpleSensorStatus.self] }
    class var sensorTypes: [SensorType] { [] }
    final var sensorTypes: [SensorType] { Self.sensorTypes }
}

/// Base class for cells displaying a history graph of sensor readings.
class SensorGraphCell: SensorCell {
    override class var height: CGFloat { kBigCellHeight }
    override var tappableInDetail: Bool { true }
    private var sensorViewController: SensorViewController!
    
    override func configure() {
        super.configure()
        if sensorViewController == nil {
            sensorViewController = SensorViewController()
            sensorViewController.loadViewIfNeeded()
            sensorViewController.view.frame = contentView.bounds
            contentView.addSubview(sensorViewController.view)
        }
        
        sensorViewController.sensorView.clear()
        sensorViewController.sensorView.keyOrder = sensorTypes.map { $0.dataKey }
        
        update()
    }
    
    override func update(animated: Bool = false) {
        
        guard let historyLimit = delegate?.historyLimit else { return }
        let now = CFAbsoluteTimeGetCurrent()
        let minTimeStamp = now - historyLimit.time
        let single = sensorTypes.count == 1
        
        // Setup graph section divisions.
        let numSections = Int((historyLimit.time / historyLimit.subLength).rounded())
        let offset = 1 - now.truncatingRemainder(dividingBy: historyLimit.subLength) / historyLimit.subLength
        let separators = (0..<numSections).map { (CGFloat($0) + CGFloat(offset)) / CGFloat(numSections) }
        sensorViewController.sensorView.separatorLocations = separators
        
        // Prepare colors.
        let bgColor = single ? sensorTypes.first!.backgroundColor: UIColor(white: 0.95, alpha: 1)
        let textColor = single ? sensorTypes.first!.darkTextColor: .black
        let separatorColor = single ? sensorTypes.first!.lineColor.withAlphaComponent(0.1) : UIColor.black.withAlphaComponent(0.05)
        backgroundColor = bgColor
        
        // Preliminary data reduction if lots of data.
        let maxTotalEntries = 2048
        let startIndex = node!.statusEntries.firstIndex(where: { $0.timeStamp >= minTimeStamp }) ?? node!.statusEntries.count - 1
        var reducedEntries = Array(node!.statusEntries[startIndex...])
        let surplusFactor = reducedEntries.count / maxTotalEntries
        if surplusFactor > 0 {
            var counter = 0
            reducedEntries = reducedEntries.filter { _ in
                counter += 1
                return counter % surplusFactor == 0
            }
        }
        
        let validSensorTypes = sensorTypes.filter { node!.statusEntries.lastStatus(for: $0) != nil }
        guard validSensorTypes.count > 0 else { NSLog("No valid sensor data!"); return }
        
        // Set title label.
        let titleStrings = validSensorTypes.map { NSAttributedString(string: (single ? $0.title: $0.shortTitle) + " ",
                                                                     attributes: [NSAttributedString.Key.foregroundColor: $0.darkTextColor]) }
        let title = NSMutableAttributedString()
        titleStrings.forEach { title.append($0) }
        title.replaceCharacters(in: NSMakeRange(title.length - 1, 1), with: "")
        sensorViewController.topRightLabel.attributedText = title
        
        // Set current value label.
        let valueStrings: [NSAttributedString] = validSensorTypes.map {
            let lastStatus = node!.statusEntries.lastStatus(for: $0)
            let str = $0.sensorString(forValue: $0.sensorValue(for: lastStatus))
            return NSAttributedString(string: (str ?? "?") + " ", attributes: [NSAttributedString.Key.foregroundColor: $0.darkTextColor])
        }
        let value = NSMutableAttributedString()
        valueStrings.forEach { value.append($0) }
        value.replaceCharacters(in: NSMakeRange(value.length - 1, 1), with: "")
        sensorViewController.bottomRightLabel.attributedText = value
        
        sensorViewController.topLeftLabel.text = nil
        sensorViewController.bottomLeftLabel.text = nil
        
        for sensorType in sensorTypes {
            
            // Get all relevant numeric sensor values.
            var sensorPoints = reducedEntries.compactMap { entry -> DataPoint? in
                guard let value = sensorType.sensorValue(for:entry.status) else { return nil }
                return DataPoint(x: Double(entry.timeStamp), y: value)
            }
            
            if let firstEntry = sensorPoints.first {
                if firstEntry.x > minTimeStamp {
                    sensorPoints.insert(DataPoint(x: minTimeStamp, y: firstEntry.y), at: 0)
                }
            }
            else {
                if let lastKnownValue = node?.statusEntries.lastValue(for: sensorType) {
                    sensorPoints.append(DataPoint(x: minTimeStamp, y: lastKnownValue))
                    sensorPoints.append(DataPoint(x: now, y: lastKnownValue))
                }
            }
            
            // Measure value span.
            let big = CGFloat.greatestFiniteMagnitude
            var maxValue = sensorType.maximumValue ?? sensorPoints.reduce(-big) { max($1.y, $0) }
            var minValue = sensorType.minimumValue ?? sensorPoints.reduce(big) { min($1.y, $0) }
            var valueSpan = max(maxValue - minValue, 0)
            if valueSpan < sensorType.minimumValueSpan {
                let mod = (sensorType.minimumValueSpan - valueSpan) / 2
                maxValue += mod
                minValue -= mod
                valueSpan = sensorType.minimumValueSpan
            }
            
            // Populate sensor view labels.
            let empty = sensorPoints.isEmpty
            if single {
                sensorViewController.topLeftLabel.text = !empty ? sensorType.sensorString(forValue: maxValue) : nil
                sensorViewController.bottomLeftLabel.text = !empty ? sensorType.sensorString(forValue: minValue) : nil
            }
            
            // Measure time span.
            let maxTime = sensorPoints.reduce(-Double(big)) { max($1.x, $0) }
            let minTime = sensorPoints.reduce(Double(big)) { min($1.x, $0) }
            let timeSpan = maxTime - minTime
            
            // Normalize values from 0-1 for graph view.
            var normalizedEntries = sensorPoints.map { DataPoint(x: timeSpan != 0 ? ($0.x - minTime) / timeSpan: 1,
                                                                 y: ($0.y - minValue) / valueSpan) }
            if timeSpan == 0 { normalizedEntries.insert(DataPoint(x: 0, y: 0.5), at: 0) }
   
            sensorViewController.sensorView.setDataPoints(normalizedEntries,
                                                          withColor: sensorType.lineColor,
                                                          forKey: sensorType.dataKey)
        }
        
        // Wait with color updates until all texts are set. Outline labels are affected.
        sensorViewController.applyColors(background: bgColor, text: textColor, separator: separatorColor)
    }
}

class AmbientLightGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ AmbientLight() ] } }
class TemperatureGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ Temperature() ] } }
class HumidityGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ Humidity() ] } }
class PressureGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ Pressure() ] } }
class ComboGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ Temperature(), Humidity(), Pressure(), AmbientLight() ] } }
class OrientationGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ AccelerationX(), AccelerationY(), AccelerationZ() ] } }
class LEDGraphCell: SensorGraphCell { override class var sensorTypes: [SensorType] { [ LEDHue(), LEDSaturation(), LEDBrightness() ] } }

/// Base class for displaying simple current sensor readings in text.
class SensorValueCell: SensorCell {
    override func configure() {
        super.configure()
        textLabel?.adjustsFontSizeToFitWidth = true
        let single = sensorTypes.count == 1
        textLabel?.textColor = single ? sensorTypes.first?.darkTextColor : .black
        textLabel?.backgroundColor = .clear
        backgroundColor = single ? sensorTypes.first?.backgroundColor : .init(white: 0.95, alpha: 1)
        update()
    }
    override func update(animated: Bool = false) {
        var text = sensorTypes.count == 1 ? "Current " + sensorTypes.first!.title.lowercased() + ": " : "Current readings: "
        if let status = node?.statusEntries.lastStatus(for: sensorTypes.first!) {
            text += sensorTypes.compactMap { $0.sensorString(forValue: $0.sensorValue(for: status)) }.joined(separator: ", ")
        }
        textLabel?.text = text
    }
}

class TemperatureValueCell: SensorValueCell { override class var sensorTypes: [SensorType] { [ Temperature() ] } }
class AmbientLightValueCell: SensorValueCell { override class var sensorTypes: [SensorType] { [ AmbientLight() ] } }
class HumidityValueCell: SensorValueCell { override class var sensorTypes: [SensorType] { [ Humidity() ] } }
class PressureValueCell: SensorValueCell { override class var sensorTypes: [SensorType] { [ Pressure() ] } }
class ComboValueCell: SensorValueCell { override class var sensorTypes: [SensorType] { [ Temperature(), Humidity(), Pressure(), AmbientLight() ] } }


class TextCell: BaseCell {
    fileprivate var label: UILabel!
    override func configure() {
        if label == nil {
            label = UILabel()
            label.frame = contentView.bounds.insetBy(dx: kTableInset, dy: 0)
            label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            contentView.addSubview(label)
        }
    }
}

/// Simple static node alias cell.
class NameCell: TextCell {
    override func configure() {
        super.configure()
        label?.text = node?.name
    }
}

/// Simple static node address cell.
class AddressCell: TextCell {
    override func configure() {
        super.configure()
        label?.text = String(format:"Unicast address: 0x%04X", node!.node.unicastAddress)
    }
}

class RequestCell: DynamicCell {
    fileprivate var stackView: UIStackView!
    fileprivate var indicator: UIActivityIndicatorView? { stackView.arrangedSubviews.last as? UIActivityIndicatorView }
    fileprivate func showIndicator() { indicator?.showAnimated(duration:0.5) }
    fileprivate func hideIndicator() { indicator?.hideAnimated(duration:0.5) }
    fileprivate func requestStatus() { }
    
    override func configure() {
        if stackView == nil {
            stackView = UIStackView(arrangedSubviews: [UIActivityIndicatorView(style: .gray)])
            stackView.alignment = .fill
            stackView.spacing = kTableInset
            stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.layoutMargins = .init(kTableInset)
            stackView.frame = contentView.bounds
            contentView.addSubview(stackView)
            
            indicator?.hidesWhenStopped = false
            indicator?.setContentHuggingPriority(.defaultLow, for: .vertical)
            indicator?.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }
        
        indicator?.stopAnimating()
        indicator?.isHidden = true
    }
}

/// Base cell for node features with on/off switches.
class SwitchCell: RequestCell {
    override class var height: CGFloat { kMediumCellHeight }
    override var tappableInOverview: Bool { false }
    var currentOn: Bool? { nil }
    var control: UISwitch!
    var label: UILabel!
    
    override func configure() {
        super.configure()
        
        if control == nil {
            label = UILabel()
            label.backgroundColor = .clear
            
            control = UISwitch()
            control.addTarget(self, action: #selector(switchAction), for: .valueChanged)
            
            stackView.insertArrangedSubview(label, at: 0)
            stackView.insertArrangedSubview(control, at: 1)
        }
        
        label.text = Self.title
        requestStatus()
    }
    
    override func update(animated: Bool = false) {
        super.update(animated: animated)
        self.control.isOn = currentOn ?? false
    }
    
    fileprivate func get() -> Bool { false }
    fileprivate func set(_ on: Bool) { }
    
    override func requestStatus() {
        if !get() { showIndicator() }
    }
    
    @objc func switchAction() {
        showIndicator()
        set(control.isOn)
    }
}

class RelayCell: SwitchCell {
    override var requestStatusTypes: [MeshMessage.Type] { [ConfigRelayStatus.self] }
    override var currentOn: Bool? { node?.relayOn }
    override class var title: String { "Relay enabled" }
    override func get() -> Bool {
        guard let node = node else { return false }
        return !node.getRelayOn().contains(.getsValue)
    }
    override func set(_ on: Bool) { node?.setRelay(on:on) }
    override func update(animated: Bool = false) {
        super.update(animated: animated)
        if node?.relayState.contains(.getsValue) == false { hideIndicator() }
    }
}

class LightSwitchCell: SwitchCell {
    override var requestStatusTypes: [MeshMessage.Type] { [GenericOnOffStatus.self, UbloxLightHSLStatus.self] }
    override var currentOn: Bool? { node?.lightSwitchOn }
    override class var title: String { "LED" }
    override func get() -> Bool {
        guard let node = node else { return false }
        return !node.getLightOn().contains(.getsValue)
    }
    override func set(_ on: Bool) { node?.setLight(on:on) }
    override func update(animated: Bool = false) {
        super.update(animated: animated)
        if node?.hslState.contains(.getsValue) == false { hideIndicator() }
    }
}

class OrientationCell: SensorCell {
    override class var sensorTypes: [SensorType] { [AccelerationX(), AccelerationY(), AccelerationZ() ] }
    var acceleration: Acceleration? { node?.statusEntries.lastStatus(for: AccelerationX())?.acceleration }
}

class Orientation3DCell: OrientationCell {
    override class var height: CGFloat { kHugeCellHeight }
    override var tappableInDetail: Bool { true }
    private(set) var sceneView: SCNView!
    private var model = OverviewModel()
    
    override func configure() {
        super.configure()
        if sceneView == nil {
            
            let cameraDistance = 20 as CGFloat
            let floorDistance = 8 as CGFloat
            
            let dark = UIColor.ublox.withAdjustedBrightness(-0.2) // UIColor(white: 0.1, alpha: 1)
            let scene = model.sceneWithLights
            sceneView = SCNView(frame: contentView.bounds)
            sceneView.scene = scene
            sceneView.backgroundColor = dark
            sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundColor = dark
            
            // Adding a black fog produces a nice spotlight effect.
            scene.fogColor = dark
            scene.fogStartDistance = cameraDistance * 0.5
            scene.fogEndDistance = cameraDistance * 2
            scene.fogDensityExponent = 0.25
            contentView.addSubview(sceneView)
            
            // Set light from straight above.
            model.lightNode.light?.intensity = 4000
            model.lightNode.position = SCNVector3(0, cameraDistance, 0)
            
            // Initalize camera view from slightly above
            let chipNode = model.model
            model.cameraNode.position = SCNVector3(0, cameraDistance * 0.7071, cameraDistance * 0.7071)
            sceneView.allowsCameraControl = false // Camera control allowed when shown as full screen.
            if #available(iOS 11.0, *) {
                sceneView.cameraControlConfiguration.allowsTranslation = false
            }
            let constraints = [SCNLookAtConstraint(target: chipNode)] as [SCNConstraint]
            sceneView.pointOfView?.constraints = constraints
            
            // Add floor to better see how chip is oriented even while swiping around.
            let floorMaterial = SCNMaterial()
            floorMaterial.lightingModel = .lambert
            let floorGeometry = SCNFloor()
            floorGeometry.reflectivity = 0.5
            floorGeometry.reflectionFalloffStart = floorDistance
            floorGeometry.reflectionFalloffEnd = floorDistance * 3
            floorGeometry.materials = [floorMaterial]
            let floorNode = SCNNode(geometry: floorGeometry)
            floorNode.position = SCNVector3(0, -floorDistance, 0)
            model.sceneWithLights.rootNode.addChildNode(floorNode)
        }
        
        update(animated: false)
    }
    
    override func update(animated: Bool = true) {
        onMain {
            guard let acc = self.acceleration else { return }
            if animated { SCNTransaction.animationDuration = 0.25 }
            
            let chipNode = self.model.model
            
            // Transform c209 coordinates to match 3D scene coordinates.
            let transAcc = SCNVector3(acc.y, acc.z, acc.x)
            
            // Calculate new Euler angles. y can't be calculated from acceleration alone.
            var xAngle = atan2(transAcc.y, transAcc.z) - .pi/2
            var zAngle = atan2(transAcc.x, sqrt(transAcc.y * transAcc.y + transAcc.z * transAcc.z))
            
            // Adjust angles to avoid >180 degree turns.
            // TODO: Do we need to adjust yAngle in some sensible way?
            let curXAngle = chipNode.eulerAngles.x
            let curZAngle = chipNode.eulerAngles.z
            while xAngle - curXAngle > Float.pi { xAngle -= 2 * .pi }
            while curXAngle - xAngle > Float.pi { xAngle += 2 * .pi }
            while zAngle - curZAngle > Float.pi { zAngle -= 2 * .pi }
            while curZAngle - zAngle > Float.pi { zAngle += 2 * .pi }
            
            // Make small adjustment to force actual update when identical values.
            // Otherwise, view may not be updated and look corrupt if previously off-screen, seen on iOS 13.
            let eps = 1e-3 as Float
            if xAngle == curXAngle && zAngle == curZAngle {
                xAngle += Float.random(in: -eps...eps)
                zAngle += Float.random(in: -eps...eps)
            }
            
            chipNode.eulerAngles = SCNVector3(xAngle, 0, zAngle)
            
            // TODO: Enable polling when firmware stability improved.
            // self.node?.pollSensor(type: .acceleration)
        }
    }
}

/// Common for cells interested in HSL status.
class HSLRequestCell: RequestCell, ColorPickerControllerDelegate {
    override var requestStatusTypes: [MeshMessage.Type] { [UbloxLightHSLStatus.self, GenericOnOffStatus.self] }
    
    override func requestStatus() {
        guard let node = node else { return }
        if node.getLightHSL().contains(.getsValue) { showIndicator() }
    }
    
    func colorChanged(_ color: UIColor) {
        showIndicator()
        node?.setLightHSL(hsl: color.hsv)
    }
    
    override func update(animated: Bool = false) {
        if node?.hslState.contains(.getsValue) == false { hideIndicator() }
    }
}

/// Cell for node LED light color control. Sliders for fine control.
class HSLSliderCell: HSLRequestCell {
    override var tappableInOverview: Bool { false }
    override class var height: CGFloat { kLEDCellHeight }
    private var colorPicker: ColorPickerController!
   
    override func configure() {
        super.configure()
        
        if colorPicker == nil {
            colorPicker = ColorPickerController()
            colorPicker.delegate = self
            
            stackView.insertArrangedSubview(colorPicker.view, at: 0)
        }
        colorPicker.isEnabled = false
        requestStatus()
    }
    
    override func update(animated: Bool = false) {
        super.update(animated: animated)
        if let hsv = node?.lightHSL {
            self.colorPicker.isEnabled = true
            self.colorPicker.setColor(UIColor(hsv: hsv), updateSliders: true)
        }
    }
}

/// Cell for node LED light color control. Buttons with predefined colors.
class HSLButtonCell: HSLRequestCell {
    override var tappableInOverview: Bool { false }
    override class var height: CGFloat { kBigCellHeight }
    private var buttons: [UIButton]!
    private var colors = [UIColor.red, .green, .blue, .magenta, .yellow, .cyan, .white]
    
    override func configure() {
        super.configure()
        if buttons == nil {
            
            buttons = colors.map {
                let button = UIButton(type: .custom)
                button.setColor($0, selected: false)
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .primaryActionTriggered)
                button.layer.cornerRadius = 8
                button.showsTouchWhenHighlighted = true
                return button
            }
                        
            let subStack = UIStackView(arrangedSubviews: buttons)
            subStack.distribution = .fillEqually
            subStack.spacing = 4
        
            stackView.insertArrangedSubview(subStack, at: 0)
        }
        
        requestStatus()
    }
    
    @objc func buttonPressed(_ button: UIButton) {
        colorChanged(colors[buttons.firstIndex(of: button) ?? 0].withBrightness(0.75))
    }
    
    override func update(animated: Bool = false) {
        super.update(animated: animated)
        if let hsv = node?.lightHSL {

            for (index, button) in buttons.enumerated() {
                let epsilon = 0.01 as CGFloat
                var hueDiff = hsv.hue - colors[index].hue
                while hueDiff > 0.5 { hueDiff -= 1 }
                while hueDiff < -0.5 { hueDiff += 1 }
                hueDiff = abs(hueDiff)
                
                let satDiff = abs(hsv.saturation - colors[index].saturation)
                let briDiff = abs(hsv.brightness - colors[index].brightness)
                
                let match = satDiff <= epsilon && hueDiff <= epsilon && briDiff < 0.5
                
                button.setColor(colors[index], selected: match)
            }
        }
    }
}

fileprivate extension UIButton {
    func setColor(_ color: UIColor, selected: Bool) {
        let useColor = color.withSaturation(min(color.saturation, 0.5))
        layer.backgroundColor = useColor.cgColor
        layer.borderColor = selected ? UIColor.black.cgColor: useColor.withAdjustedBrightness(-0.1).cgColor
        layer.borderWidth = selected ? 3: 2
    }
}

// Descriptions of the available sensor types.

private let saturation = 0.4 as CGFloat
private let red = UIColor.red.withSaturation(saturation)
private let green = UIColor.green.withSaturation(saturation).withBrightness(0.7)
private let blue = UIColor.blue.withSaturation(saturation).withBrightness(1.0)
private let magenta = UIColor.magenta.withSaturation(saturation).withBrightness(0.9)
private let cyan = UIColor.cyan.withSaturation(saturation).withBrightness(0.9)
private let yellow = UIColor.yellow.withSaturation(saturation).withBrightness(0.7)

protocol SensorType {
    var title: String { get }
    var shortTitle: String { get }
    var lineColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var darkTextColor: UIColor { get }
    func sensorValue(for status: SensorStatus?) -> CGFloat?
    func sensorString(forValue value:CGFloat?) -> String?
    var dataKey: String { get }
    var minimumValue: CGFloat? { get }
    var maximumValue: CGFloat? { get }
    var minimumValueSpan: CGFloat { get }
}

private extension SensorType {
    var shortTitle: String { title }
    var backgroundColor: UIColor { lineColor.withSaturation(0.1).withBrightness(1) }
    var darkTextColor: UIColor { lineColor.withBrightness(0.6) }
    var dataKey: String { title.lowercased() }
    var minimumValue: CGFloat? { nil }
    var maximumValue: CGFloat? { nil }
    var minimumValueSpan: CGFloat { (maximumValue ?? 1) - (minimumValue ?? 0) }
}

private struct AmbientLight: SensorType {
    var title: String { "Ambient light" }
    var shortTitle: String { "Amb" }
    var lineColor: UIColor { yellow }
    var minimumValueSpan: CGFloat { 2 }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.ambientLightLux }
    func sensorString(forValue value:CGFloat?) -> String? { value != nil ? String(format: "%.0f Lux", value!): nil }
}

private struct Temperature: SensorType {
    var title: String { "Temperature" }
    var shortTitle: String { "Temp" }
    var lineColor: UIColor { red }
    var minimumValueSpan: CGFloat { 1 }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.degreesCelsius }
    func sensorString(forValue value:CGFloat?) -> String? { value != nil ? String(format: "%.1f ℃", value!): nil }
}

private struct Humidity: SensorType {
    var title: String { "Humidity" }
    var shortTitle: String { "Hum" }
    var lineColor: UIColor { blue }
    var minimumValueSpan: CGFloat { 6 }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.humidityPercent }
    func sensorString(forValue value:CGFloat?) -> String? { value != nil ? String(format: "%.0f %%", value!): nil }
}

private struct Pressure: SensorType {
    var title: String { "Air pressure" }
    var shortTitle: String { "Air" }
    var lineColor: UIColor { green }
    var minimumValueSpan: CGFloat { 40 }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.milliBars }
    func sensorString(forValue value:CGFloat?) -> String? { value != nil ? String(format: "%.1f mB", value!): nil }
}

private protocol AccelerationSensor: SensorType { }
private extension AccelerationSensor {
    var minimumValue: CGFloat? { -1 }
    var maximumValue: CGFloat? { 1 }
    func sensorString(forValue value:CGFloat?) -> String? { value != nil ? String(format: "%.2f", value!): nil }
}

private struct AccelerationX: AccelerationSensor {
    var title: String { "X" }
    var lineColor: UIColor { magenta }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.acceleration?.x }
}

private struct AccelerationY: AccelerationSensor {
    var title: String { "Y" }
    var lineColor: UIColor { cyan }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.acceleration?.y }
}

private struct AccelerationZ: AccelerationSensor {
    var title: String { "Z" }
    var lineColor: UIColor { yellow }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.acceleration?.z }
}

private protocol HSVComponent: SensorType { }
private extension HSVComponent {
    var minimumValue: CGFloat? { 0 }
    var maximumValue: CGFloat? { 1 }
    func sensorString(forValue value:CGFloat?) -> String? { value != nil ? String(format: "%.2f", value!): nil }
}

private struct LEDHue: HSVComponent {
    var title: String { "Hue" }
    var lineColor: UIColor { magenta }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.color != nil ? CGFloat(status!.color!.hue): nil }
}

private struct LEDSaturation: HSVComponent {
    var title: String { "Saturation" }
    var shortTitle: String { "Sat" }
    var lineColor: UIColor { cyan }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.color != nil ? CGFloat(status!.color!.saturation): nil }
}

private struct LEDBrightness: HSVComponent {
    var title: String { "Brightness" }
    var shortTitle: String { "Bri" }
    var lineColor: UIColor { yellow }
    func sensorValue(for status: SensorStatus?) -> CGFloat? { status?.color != nil ? CGFloat(status!.color!.brightness): nil }
}

/// Shown as table header before any nodes detected and used to indicate proxy connection progress.
class ConnectionCell: BaseCell {
    private static let margin = kTableInset as CGFloat
    override class var height: CGFloat { 44 + 2 * margin }
    private(set) var label = UILabel()
    private(set) var indicator = UIActivityIndicatorView(style: .gray)
    private(set) var progressView = UIProgressView(progressViewStyle: .default)
    private var vStackView: UIStackView!
    
    override func configure() {
        if vStackView == nil {
            let margin = Self.margin
            
            vStackView = UIStackView()
            vStackView.axis = .vertical
            vStackView.layoutMargins = .init(top: margin, left: margin, bottom: margin, right: margin)
            vStackView.isLayoutMarginsRelativeArrangement = true
            vStackView.spacing = margin
            
            let hStackView = UIStackView()
            hStackView.alignment = .center
            hStackView.spacing = margin
            
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.numberOfLines = 1
            label.font = .italicSystemFont(ofSize: label.font.pointSize)
                
            indicator.hidesWhenStopped = false
            indicator.isHidden = false
            
            hStackView.addArrangedSubview(label)
            hStackView.addArrangedSubview(indicator)

            vStackView.addArrangedSubview(hStackView)
            vStackView.addArrangedSubview(progressView)
            vStackView.frame = self.contentView.bounds
            vStackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.contentView.addSubview(vStackView)
        }
        
        progressView.progress = 0.01
        
        indicator.startAnimating()
    }
}

class CadenceCell: RequestCell {
    override var requestStatusTypes: [MeshMessage.Type] { [ConfigModelPublicationStatus.self] }
    override class var height: CGFloat { kBigCellHeight }
    private var vStackView: UIStackView!
    private var control: UISegmentedControl!
    private let values = [5, 10, 15, 30, 60, 300]
    
    override func configure() {
        super.configure()
        
        if vStackView == nil {
            
            let label = UILabel()
            label.text = "Sensor publish interval [sec]"
            
            control = UISegmentedControl(items: values.map { "\($0)" })
            control.addTarget(self, action: #selector(segmentAction), for: .valueChanged)
            control.isEnabled = true
            
            vStackView = UIStackView()
            vStackView.axis = .vertical
            vStackView.spacing = 8
            vStackView.addArrangedSubview(label)
            vStackView.addArrangedSubview(control)
            
            stackView.insertArrangedSubview(vStackView, at: 0)
        }

        requestStatus()
    }
    
    override func update(animated: Bool = false) {
        if let interval = node?.interval {
            self.control.selectedSegmentIndex = self.values.firstIndex(of: interval) ?? -1
        }
        if node?.intervalState.contains(.getsValue) == false { hideIndicator() }
    }
    
    override func requestStatus() {
        guard let node = node else { return }
        if node.getInterval().contains(.getsValue) { showIndicator() }
    }
    
    @objc func segmentAction() {
        showIndicator()
        node?.setInterval(interval: values[control.selectedSegmentIndex])
    }
}
