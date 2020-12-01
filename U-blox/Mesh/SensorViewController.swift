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

struct DataPoint {
    var x: Double
    var y: CGFloat
    var cgPoint: CGPoint { CGPoint(x: CGFloat(x), y: y) }
}

class SensorView: UIView {

    private let kMaxDataPoints = 1024 as Double
    private let kLineWidth = 2 as CGFloat
    fileprivate var margin = 8 as CGFloat

    var keyOrder: [String]?
    var separatorLocations = [CGFloat]() { didSet { updateSections(animated: false) } }
    var separatorColor = UIColor.black { didSet { sectionLayer.strokeColor = separatorColor.cgColor }}
    
    private var dataPointSets = [String: [[DataPoint]]]()
    private var shapeLayers = [String: CAShapeLayer]()
    private var gapShapeLayers = [String: CAShapeLayer]()
    private var sectionLayer = CAShapeLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sectionLayer.lineWidth = kLineWidth
        sectionLayer.fillColor = nil
        sectionLayer.strokeColor = separatorColor.cgColor
        sectionLayer.lineCap = .round
        sectionLayer.lineJoin = .round
        layer.insertSublayer(sectionLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayers.keys.forEach { updateShapes(forKey: $0, animated: true) }
        updateSections(animated: true)
    }
    
    private func getTransform(forKey key: String? = nil) -> CGAffineTransform {
        
        let numKeys = key != nil ? keyOrder?.count ?? 1 : 1
        let keyIndex = key != nil ? keyOrder?.firstIndex(of: key!) ?? 0 : 0
        
        let offset = 1 * kLineWidth
        let insetHeight = bounds.size.height - 2 * margin
        let subHeight = insetHeight - CGFloat(numKeys - 1) * offset
        
        return CGAffineTransform.identity
            .translatedBy(x: 0, y: bounds.size.height - margin - CGFloat(numKeys - keyIndex - 1) * offset)
            .scaledBy(x: bounds.size.width, y: -subHeight)
    }
    
    private func controlPoints(_ from: CGPoint, _ to: CGPoint) -> (CGPoint, CGPoint) {
        (CGPoint(x: from.x.interpolate(to: to.x, t: 0.33), y: from.y),
         CGPoint(x: from.x.interpolate(to: to.x, t: 0.67), y: to.y))
    }
    
    private func updateShapes(forKey key:String, animated: Bool) {
        
        let path = CGMutablePath()
        let gapPath = CGMutablePath()
        let transform = getTransform(forKey: key)
        guard let batches = dataPointSets[key] else { return }
        for batch in batches {
            
            if batch.count > 0 {
                
                // Build batches of sensor readings.
                var to = batch.first!.cgPoint
                path.move(to: to, transform: transform)
                var from = to
                for index in 0..<batch.count {
                    to = batch[index].cgPoint
                    let cp = controlPoints(from, to)
                    path.addCurve(to: to, control1: cp.0, control2: cp.1, transform: transform)
                    from = to
                }
                
                // Add the dashed gap path between batches.
                if gapPath.isEmpty { gapPath.move(to: CGPoint(x: 0, y: 0.5), transform: transform) }
                from = gapPath.currentPoint
                to = batch.first!.cgPoint.applying(transform)
                let cp = controlPoints(from, to)
                gapPath.addCurve(to: to, control1: cp.0, control2: cp.1)
                
                gapPath.move(to: batch.last!.cgPoint, transform: transform)
            }
        }
        
        if animated {
            let a1 = CABasicAnimation(keyPath: "path")
            a1.fromValue = shapeLayers[key]?.path
            a1.toValue = path
            shapeLayers[key]?.add(a1, forKey: nil)
            
            let a2 = CABasicAnimation(keyPath: "path")
            a2.fromValue = gapShapeLayers[key]?.path
            a2.toValue = gapPath
            gapShapeLayers[key]?.add(a2, forKey: nil)
        }
        
        shapeLayers[key]?.path = path
        gapShapeLayers[key]?.path = gapPath
    }
    
    private func updateSections(animated: Bool) {
        let path = CGMutablePath()
        let transform = getTransform()

        separatorLocations.forEach { x in
            path.move(to: CGPoint(x: x, y: 0), transform: transform)
            path.addLine(to: CGPoint(x: x, y: 1), transform: transform)
        }
        
        if animated {
            let a = CABasicAnimation(keyPath: "path")
            a.fromValue = sectionLayer.path
            a.toValue = path
            sectionLayer.add(a, forKey: nil)
        }
        sectionLayer.path = path
    }
    
    func setDataPoints(_ dataPoints: [DataPoint], withColor color: UIColor, forKey key:String) {
        
        guard dataPoints.count > 0 else { return }
        
        // Measure minimum time step to help detect sensor reading time gaps.
        let minXStep = max(dataPoints[1...].reduce((Double.infinity, -Double.infinity)) { (result, curPoint) in
            (min(result.0, curPoint.x - result.1), curPoint.x)
        }.0, 0.005)
        
        // Build point batches
        dataPointSets[key] = [[DataPoint]]()
        var currentBatch = [DataPoint]()
        var lastAddedPoint = dataPoints.first!
        var prevPoint = dataPoints.first!
        for curPoint in dataPoints[1...] {
            
            // Check if near enough in time to be part of same reading batch.
            if curPoint.x - prevPoint.x < 8 * minXStep {
                if currentBatch.isEmpty {
                    currentBatch.append(prevPoint)
                }
            }
            else if !currentBatch.isEmpty {
                dataPointSets[key]?.append(currentBatch)
                currentBatch.removeAll()
            }
            
            // Check if distant enough in time from previous to actually draw this point.
            if curPoint.x - lastAddedPoint.x >= 1 / kMaxDataPoints {
                currentBatch.append(curPoint)
                lastAddedPoint = curPoint
            }
            prevPoint = curPoint
        }
        dataPointSets[key]?.append(currentBatch)
        
        if shapeLayers[key] == nil {
            let shapeLayer = CAShapeLayer()
            shapeLayer.lineWidth = kLineWidth
            shapeLayer.fillColor = nil
            shapeLayer.strokeColor = color.cgColor
            shapeLayer.lineCap = .round
            shapeLayer.lineJoin = .round
            shapeLayers[key] = shapeLayer
            layer.insertSublayer(shapeLayer, at: 1)
            
            let gapShapeLayer = CAShapeLayer()
            gapShapeLayer.lineWidth = kLineWidth
            gapShapeLayer.fillColor = nil
            gapShapeLayer.strokeColor = color.withAlphaComponent(0.25).cgColor
            gapShapeLayer.lineCap = .round
            gapShapeLayer.lineJoin = .round
            gapShapeLayer.lineDashPattern = [0, 2 * kLineWidth].map { NSNumber(floatLiteral: Double($0)) }
            gapShapeLayers[key] = gapShapeLayer
            layer.insertSublayer(gapShapeLayer, at: 1)
        }

        updateShapes(forKey: key, animated: false)
    }
    
    func clear() {
        dataPointSets.removeAll()
        shapeLayers.values.forEach { $0.removeFromSuperlayer() }
        shapeLayers.removeAll()
        gapShapeLayers.values.forEach { $0.removeFromSuperlayer() }
        gapShapeLayers.removeAll()
        keyOrder?.removeAll()
    }
}

class SensorViewController: UIViewController {
    @IBOutlet var topLeftLabel: UILabel!
    @IBOutlet var bottomLeftLabel: UILabel!
    @IBOutlet var bottomRightLabel: UILabel!
    @IBOutlet var topRightLabel: UILabel!
    
    @IBOutlet var topLeftBackLabel: UILabel!
    @IBOutlet var bottomLeftBackLabel: UILabel!
    @IBOutlet var bottomRightBackLabel: UILabel!
    @IBOutlet var topRightBackLabel: UILabel!
    
    @IBOutlet var sensorView: SensorView!
    
    var backLabels: [UILabel] { [topLeftBackLabel, bottomLeftBackLabel, topRightBackLabel, bottomRightBackLabel] }
    var frontLabels: [UILabel] { [topLeftLabel, bottomLeftLabel, topRightLabel, bottomRightLabel] }
    var allLabels: [UILabel] { frontLabels + backLabels }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Makes sure there's space enough in labels to not clip the label background outlines.
        let grow = 8 as CGFloat
        let xMargin = kTableInset as CGFloat
        let yMargin = 8 as CGFloat
        allLabels.forEach { label in
            label.textAlignment = .center
            label.sizeToFit()
            label.bounds.size.width += 2 * grow
            label.bounds.size.height += 2 * grow
            let mask = label.autoresizingMask
            if mask.contains(.flexibleRightMargin) { label.center.x = xMargin + label.width / 2 - grow }
            if mask.contains(.flexibleLeftMargin) { label.center.x = view.width - xMargin - label.width / 2 + grow }
            if mask.contains(.flexibleBottomMargin) { label.center.y = yMargin + label.height / 2 - grow }
            if mask.contains(.flexibleTopMargin) { label.center.y = view.height - yMargin - label.height / 2 + grow }
        }
        
        // Let graphs intersect labels if compact view but not in a large.
        let minMargin = 8 as CGFloat
        let maxMargin = topRightLabel.frame.maxY - grow + 16
        let minimumGraphHeight = 80 as CGFloat
        let height = sensorView.height
        let large = height - 2 * maxMargin >= minimumGraphHeight
        sensorView.margin = large ? maxMargin: minMargin
       
        // Group the current reading with the title in large views.
        [bottomRightLabel!, bottomRightBackLabel!].forEach {
            $0.center.y = large ? topRightLabel.frame.maxY + $0.height / 2 + yMargin - 2 * grow: height - $0.height / 2 - yMargin + grow
            $0.autoresizingMask = [large ? .flexibleBottomMargin: .flexibleTopMargin, .flexibleLeftMargin]
        }
    }
    
    func applyColors(background: UIColor, text: UIColor, separator: UIColor) {
        [topLeftLabel, bottomLeftLabel].forEach { $0?.textColor = text }
        sensorView.separatorColor = separator
        
        zip(backLabels, frontLabels).forEach {
            let newStr = NSMutableAttributedString()
            if let str = $0.1.attributedText {
                newStr.append(str)
                newStr.addAttributes([NSAttributedString.Key.strokeWidth: 30, // Stroke width 30% of font size
                    NSAttributedString.Key.strokeColor: background.withAlphaComponent(0.8)],
                                     range: NSMakeRange(0, newStr.length))
            }
            $0.0.attributedText = newStr
        }
        
    }
}
