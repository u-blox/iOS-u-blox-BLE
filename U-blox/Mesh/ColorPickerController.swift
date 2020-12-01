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

protocol ColorPickerControllerDelegate: AnyObject {
    func colorChanged(_ color: UIColor)
}

class ColorPickerController: UIViewController {
    
    private var color = UIColor.white
    
    func setColor(_ color: UIColor, updateSliders: Bool = true) {
        loadViewIfNeeded()
        
        self.color = color
        colorView.backgroundColor = color
        
        if updateSliders {
            let hsv = color.hsv
            hSlider.value = Float(hsv.hue)
            sSlider.value = Float(hsv.saturation)
            vSlider.value = Float(hsv.brightness)
        }
    }
    
    var isEnabled = false {
        didSet {
            hSlider.isEnabled = isEnabled
            sSlider.isEnabled = isEnabled
            vSlider.isEnabled = isEnabled
            if !isEnabled {
                setColor(.black, updateSliders: true)
            }
        }
    }
    
    private var timer: Timer?
    
    @IBOutlet private var colorView: UIView!
    
    @IBOutlet private var hSlider: UISlider!
    @IBOutlet private var sSlider: UISlider!
    @IBOutlet private var vSlider: UISlider!
    
    weak var delegate: ColorPickerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        colorView.layer.masksToBounds = true
        colorView.layer.cornerRadius = 10
        colorView.layer.borderWidth = 2
        colorView.layer.borderColor = UIColor.lightGray.cgColor
                
        hSlider.value = Float(color.hue)
        sSlider.value = Float(color.saturation)
        vSlider.value = Float(color.brightness)
        
        isEnabled = true
    }
    
    @IBAction func sliderChanged(_ slider: UISlider) {
        setColor(UIColor(hue: CGFloat(hSlider.value), saturation: CGFloat(sSlider.value), brightness: CGFloat(vSlider.value), alpha: 1), updateSliders: false)
        
        // Send color change message, but not while dragging sliders.
        timer?.invalidate()
        timer = .scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            self.delegate?.colorChanged(self.color)
        })
    }
}
